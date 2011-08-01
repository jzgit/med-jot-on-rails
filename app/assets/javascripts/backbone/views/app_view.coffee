jQuery ->
  # The Application
  # ---------------

  # Our overall **AppView** is the top-level piece of UI.
  class Railsjot.Views.AppView extends Backbone.View

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
      view = new Railsjot.Views.JotView model: jot
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
        [content, context] = @jotROS(@input.val())


        attrs.content = content || @input.val()
        attrs.location = @currentDestination
        attrs.context = context || ''
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
            @saveROS()
            @showROS()



    saveROS: () ->
      for section in $('.ros-section')
        # name = section.('.ros-section > h3').text()
        positives = $('.ros-yes').next().text()
        negatives = $('.ros-no').next().text()
        alert $(section).length



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
        [all, flag, content] = val.match(/(\w\w)(.*)/i)
        flag = flag.toUpperCase()
        symptom = @$('.ros-content.'+ flag).text()
        section = @$('.ros-content.'+ flag).closest('.ros-section').find('h3').text()
        context = section + '-' + symptom
      [content, context]

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
  window.App = new Railsjot.Views.AppView()



