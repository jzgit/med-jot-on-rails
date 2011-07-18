#= require_self
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./routers

root = global ? window

root.Railsjot =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}



# An example Backbone application contributed by
# [Jérôme Gravel-Niquet](http:#jgn.me/). This demo uses a simple
# [LocalStorage adapter](backbone-localstorage.html)
# to persist Backbone models within your browser.

# Load the application once the DOM is ready, using `jQuery.ready`:

# Jot Model
# ----------
jQuery ->
  # Our basic **Jot** model has `content`, `order`, and `done` attributes.
  class root.Jot extends Backbone.Model

    #urlRoot: '/jots'

    # Remove this Jot from *localStorage* and delete its view.
    clear: -> 
      @destroy()
      @view.remove()

  # Jot Collection
  # ---------------

  # The collection of jots is backed by *localStorage* instead of a remote
  # server.
  class root.JotList extends Backbone.Collection

    # Reference to this collection's model.
    model: root.Jot

    url: '/jots'

    # We keep the Jots in sequential order, despite being saved by unordered
    # GUID in the database. This generates the next order number for new items.
    nextOrder: ->
      if (@length) then @last().get('order') + 1 else 1

    # Jots are sorted by their original insertion order.
    comparator: (jot) ->
      jot.get('order')


  # Create our global collection of **Jots**.
  root.Jots = new JotList()

  # history view (right panel of classified info)
  class root.HistoryView extends Backbone.View
    el:           ($ '.history-content')
    tagName:      'div'
    template: JST["backbone/templates/history"]

    sections:
      'Patient Info': 'PT'
      'Chief Complaint': 'CC'
      'History of Present Illness': 'HPI'
      'Past Medical History': 'PMH'
      'Past Surgical History': 'PSH'
      'Medications': 'MEDS'
      'Allergies': 'ALL'
      'Social History': 'SH'
      'Family History': 'FH'
      'Review of Systems': 'ROS'


    initialize: ->
      _.bindAll(this, 'render')
      $(@el).html(@template({@sections}))
      @


  root.History = new HistoryView()

  # Review of systems View

  class root.ROSView extends Backbone.View

    el:  ($ '.ros-container')
    tagName:  'div'
    template: JST["backbone/templates/ros-section"]

    initialize: ->
      _.bindAll(this, 'render')
      $(@el).html @template
      @


  root.Ros = new ROSView()


  # Jot Item View
  # --------------

  # The DOM element for a jot item...
  class root.JotView extends Backbone.View

    #... is a list tag.
    tagName:  "li"

    # Cache the template function for a single item.
    template: JST["backbone/templates/jot"]

    # The DOM events specific to an item.
    events:
      "dblclick div.jot-content" : "edit"
      "click span.jot-destroy"   : "clear"
      "keypress .jot-input"      : "updateOnEnter"
      "click .jot-move"          : "setLocation"

    # The JotView listens for changes to its model, re-rendering. Since there's
    # a one-to-one correspondence between a **Jot** and a **JotView** in this
    # app, we set a direct reference on the model for convenience.
    initialize: -> 
      _.bindAll this, 'render', 'close'
      @model.bind 'change', @render
      @model.bind 'destroy', => @remove()

    # Re-render the contents of the jot item.
    render: -> 
      $(@el).html(@template(@model.toJSON()))
      @setContent()
      this


    # To avoid XSS (not that it would be harmful in this particular app),
    # we use `jQuery.text` to set the contents of the jot item.
    setContent: -> 
      content = @model.get 'content'
      @$('.jot-content').text content
      @input = @$('.jot-input')
      @input.bind('blur', @close)
      @input.val content


    setLocation: (e) ->
      @model.set location: $(e.target).text()
      @remove()
      @model.save()


    # Switch this view into `"editing"` mode, displaying the input field.
    edit: ->
      $(@el).addClass "editing"
      @input.focus()


    # Close the `"editing"` mode, saving changes to the jot.
    close: ->
      @model.save content: @input.val()
      $(@el).removeClass "editing"


    # If you hit `enter`, we're through editing the item.
    updateOnEnter: (e) ->
      @close() if e.keyCode is 13


    # Remove the item, destroy the model.
    clear: ->
      @model.destroy()

  # The Application
  # ---------------

  # Our overall **AppView** is the top-level piece of UI.
  class root.AppView extends Backbone.View

    # Instead of generating a new element, bind to the existing skeleton of
    # the App already present in the HTML.
    el: $("#center-app")

    # Our template for the line of statistics at the bottom of the app.
    destinationTemplate: JST["backbone/templates/destination"]

    # Delegated events for creating new items, and clearing completed ones.
    events: 
      "keypress #new-jot" : "createOnEnter"
      "keyup #new-jot"    : "checkText"
      "click span#help"    : "showHelp"
      "click .tag"         : "setAutoTag"

    # At initialization we bind to the relevant events on the `Jots`
    # collection, when items are added or changed. Kick things off by
    # loading any preexisting jots that might be saved in *localStorage*.
    initialize: -> 
      _.bindAll(this, 'addOne', 'addAll', 'render', 'setAutoTag', 'showHelp', 'checkText', 'showROS',  'jotROS', 'checkFlags', 'cycleROS', 'markROS')

      @input    = @$("#new-jot")

      @currentDestination = "JOT"
      @currentROS = 0

      Jots.bind 'add', @addOne
      Jots.bind 'reset', @addAll
      Jots.bind 'change:location', @addOne
      Jots.bind 'all', @render

      Jots.fetch()

    # Re-rendering the App just means refreshing the autotag display -- the rest
    # of the app doesn't change.
    render: -> 
      current = @currentDestination.toLowerCase()
      @$('#current-destination').html(@destinationTemplate())
      @$('.auto-tag').children().removeClass('current-tag').filter('.' + current).addClass('current-tag')
      @toggleDetails current

    setAutoTag: (e) ->
      @input.focus()
      @currentDestination = $(e.target).text()
      @render()



    # Add a single jot item to the list by creating a view for it, and
    # appending its element to the `<ul>`.
    addOne: (jot) ->
      view = new JotView model: jot
      location = jot.get('location').toLowerCase()
      $(".jot-list").filter('.'+location).append(view.render().el)


    # Add all items in the **Jots** collection at once.
    addAll: ->
      Jots.each @addOne


    # Generate the attributes for a new Jot item.
    newAttributes: ->
      content: @input.val()
      order:   Jots.nextOrder()

    # If you hit return in the main input field, create new **Jot** model,
    # persisting it to *localStorage*.
    createOnEnter: (e) ->
      if e.keyCode is 13
        attrs = @newAttributes()
        # checks for ROS symptom flags before assigning content
        attrs.content = @jotROS @input.val()
        attrs.location = @currentDestination

        Jots.create attrs
        @input.val('')

    #reshow help menu
    showHelp: ->
      $("#guider_overlay").fadeIn("fast")
      $('.guider').fadeIn("fast")

    # check for flags in input (.hpi, .ros, .pmh)
    checkFlags: (val) ->
      if /\.(pt|cc|hpi|pmh|psh|meds|all|sh|fh|ros|jot)/i.test val
        flag = val.match /\.(pt|cc|hpi|pmh|psh|meds|all|sh|fh|ros|jot)/i
        @currentDestination = flag[1].toUpperCase()
        @val = val.replace /\.(pt|cc|hpi|pmh|psh|meds|all|sh|fh|ros|jot)/i, ""
        @input.val @val
        @render()

    # cycle ROS categories with < or >
    cycleROS: () ->
      #cycle ROS
      c = if @currentROS > 0 then @currentROS else 1
      if /</.test(@val) and c > 0 then c -= 1
      if />/.test(@val) and c < 13 then c += 1
      @currentROS = c
      @val = @val.replace /(<|>)/i, ""
      @showROS()
      @input.val(@val)


    #  handles marking symptoms on ROS
    #  ROS navigation and highlighting
    #  needs to be refactored further
    markROS: () ->
      # remove previous highlights
      @$('.ros-state').removeClass('highlight-keycode')
      @$('.ros-item').removeClass('last-ros')

      if /\w/i.test(@val) and not /(\.|-)/.test(@val)

          #highlight section on first letter
          @$('.'+ @val.toUpperCase()).addClass('highlight-keycode')
          if /\w\w/i.test(@val)

            @val = @val.toUpperCase()
            rosItem = @$('.' + @val)

            # make sure ROS section is in view ( dont want to mark non visable sections ) #
            if $('.' + @val).parent().parent().parent().is(':visible')
              # toggles yes/no/unasked
              if (rosItem.hasClass('ros-yes'))
                rosItem.removeClass('ros-yes').filter('.ros-content').addClass('ros-no')
              else if (rosItem.hasClass('ros-no'))
                rosItem.removeClass('ros-no')
              else 
                rosItem.filter('.icon').addClass('ros-yes')


              @currentROS = rosItem.parent().addClass('last-ros').parent().parent().index()

            @input.val('')
            @showROS()





    # on keyup check input box for commands flags shortcuts
    checkText: (e) ->
      @val = @input.val()
      @checkFlags(@val)

      # ROS section controls
      if @currentDestination is 'ROS'
        # cycle ROS
        @cycleROS()
        @markROS()

    # add jots to ros symptoms with a dash
    # example if SA is keycode for headache
    # "-sa 6 over the past week" would add a specific jot
    # to the headache symptom of ROS
    jotROS: (val) -> 
      if /-(\w\w)\b/i.test(val) and @currentDestination is 'ROS'
        match = val.match(/(\w\w)(.*)/i)
        flag = match[1].toUpperCase()
        extra = match[2]
        symptom = @$('.ros-content.'+ flag).text()
        section = @$('.ros-content.'+ flag).parent().parent().parent().find('h3').text()
        content = '[' + section + '-' + symptom + ']' + ':'+ extra
      content || val

    # show active ROS sections (have too many sections to show all at once)
    showROS: ->
      sections = @$('.ros-container').children().hide()
      start = if @currentROS > 0 then @currentROS else 1
      sections[start-1..start+2].show().index()

    # toggle details container below input for extras
    toggleDetails: (current) ->
      @$('.details').hide()
      @$('.' + current + '-container').show()
      @showROS()


  # Finally, we kick things off by creating the **App**.
  root.App = new AppView()



