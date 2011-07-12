#= require_self
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./routers

window.Railsjot =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}



# An example Backbone application contributed by
# [Jérôme Gravel-Niquet](http:#jgn.me/). This demo uses a simple
# [LocalStorage adapter](backbone-localstorage.html)
# to persist Backbone models within your browser.

# Load the application once the DOM is ready, using `jQuery.ready`:

# Todo Model
# ----------
jQuery ->
  # Our basic **Todo** model has `content`, `order`, and `done` attributes.
  class window.Todo extends Backbone.Model

    # Default attributes for the todo.
    defaults: 
      content: "empty todo..."
      location: "JOT"
      context: ""
      order: 0

    

    # Ensure that each todo created has `content`.
    initialize: ->
      unless @get 'content'
        @set "content": @defaults.content



    

    # Remove this Todo from *localStorage* and delete its view.
    clear: -> 
      @destroy()
      @view.remove()



  # Todo Collection
  # ---------------

  # The collection of todos is backed by *localStorage* instead of a remote
  # server.
  class window.TodoList extends Backbone.Collection

    # Reference to this collection's model.
    model: window.Todo

    # Save all of the todo items under the `"todos"` namespace.
    #localStorage: new Store "todos"
    #
    url: '/jots'




    # We keep the Todos in sequential order, despite being saved by unordered
    # GUID in the database. This generates the next order number for new items.
    nextOrder: ->
      if (@length) then @last().get('order') + 1 else 1
    

    # Todos are sorted by their original insertion order.
    comparator: (todo) ->
      todo.get('order')
    



  # Create our global collection of **Todos**.
  window.Todos = new TodoList()


  # history view (right panel of classified info)
  class window.HistoryView extends Backbone.View
    el:           ($ '.history-content')
    tagName:      'div'
    template: JST["backbone/templates/history"]

    sectionsList =
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
      @render()


    render: ->
      #$(@el).html('<h1>history</h1>')
      $(@el).html(@template(sections: @sectionList))
      @


  window.History = new HistoryView()

  # Review of systems View

  class window.RosView extends Backbone.View

    el:  ($ '.ros-container')
    tagName:  "div"
    template: JST["backbone/template/ros-section"]

    initialize: ->
      _.bindAll(this, 'render')
    @

    render: ->
      $(@el).html(@template()(sections: {'blah': 'BL'}))
      @

  window.Ros = new RosView()


  # Todo Item View
  # --------------

  # The DOM element for a todo item...
  class window.TodoView extends Backbone.View

    #... is a list tag.
    tagName:  "li"

    # Cache the template function for a single item.
    #template: _.template($('#item-template').html())
    #template: _.template(JST["backbone/templates/jot"])
    template: JST["backbone/templates/jot"]

    # The DOM events specific to an item.
    events: 
      "dblclick div.todo-content" : "edit"
      "click span.todo-destroy"   : "clear"
      "keypress .todo-input"      : "updateOnEnter"
    

    # The TodoView listens for changes to its model, re-rendering. Since there's
    # a one-to-one correspondence between a **Todo** and a **TodoView** in this
    # app, we set a direct reference on the model for convenience.
    initialize: -> 
      _.bindAll(this, 'render', 'close')
      @model.bind('change', @render)
      @model.view = this
    

    # Re-render the contents of the todo item.
    render: -> 
      $(@el).html(@template(@model.toJSON()))
      @setContent()
      this
    

    # To avoid XSS (not that it would be harmful in this particular app),
    # we use `jQuery.text` to set the contents of the todo item.
    setContent: -> 
      content = @model.get 'content'
      @$('.todo-content').text content
      @input = @$('.todo-input')
      @input.bind('blur', @close)
      @input.val content
    

    

    # Switch this view into `"editing"` mode, displaying the input field.
    edit: -> 
      $(@el).addClass "editing"
      @input.focus()
    

    # Close the `"editing"` mode, saving changes to the todo.
    close: -> 
      @model.save content: @input.val()
      $(@el).removeClass "editing"
    

    # If you hit `enter`, we're through editing the item.
    updateOnEnter: (e) ->
      @close() if e.keyCode is 13
    

    # Remove this view from the DOM.
    remove: -> 
      $(@el).remove()
    

    # Remove the item, destroy the model.
    clear: -> 
      @model.clear()
   



  # The Application
  # ---------------

  # Our overall **AppView** is the top-level piece of UI.
  class window.AppView extends Backbone.View

    # Instead of generating a new element, bind to the existing skeleton of
    # the App already present in the HTML.
    el: $("#center-app")

    # Our template for the line of statistics at the bottom of the app.
    #statsTemplate: _.template $('#stats-template').html()
    #statsTemplate: _.template(JST["backbone/templates/stats"])
    destinationTemplate: JST["backbone/templates/destination"]

    # Delegated events for creating new items, and clearing completed ones.
    events: 
      "keypress #new-todo":  "createOnEnter"
      "click .tag"        :  "setAutoTag"

    

    # At initialization we bind to the relevant events on the `Todos`
    # collection, when items are added or changed. Kick things off by
    # loading any preexisting todos that might be saved in *localStorage*.
    initialize: -> 
      _.bindAll(this, 'addOne', 'addAll', 'render', 'setAutoTag', 'move')
      
      @input    = @$("#new-todo")

      @currentDestination = "JOT"

      window.Todos.bind('add',     @addOne)
      window.Todos.bind('reset',   @addAll)
      window.Todos.bind('all',     @render)

      window.Todos.fetch()
    

    # Re-rendering the App just means refreshing the statistics -- the rest
    # of the app doesn't change.
    render: -> 
      current = @currentDestination.toLowerCase()
      @$('#current-destination').html(@destinationTemplate())
      @$('.auto-tag').children().removeClass('current-tag').filter('.' + current).addClass('current-tag')
      #@toggleDetails current

    setAutoTag: (e) ->
      @input.focus()
      @currentDestination = $(e.target).text()
      @render()


    move: (todo) ->
      todo.view.remove()
      view = new window.TodoView model: todo
      location = todo.get('location').toLowerCase()
      $(".jot-list").filter('.'+location).append(view.render().el)


    # Add a single todo item to the list by creating a view for it, and
    # appending its element to the `<ul>`.
    addOne: (todo) -> 
      view = new window.TodoView model: todo
      #if todo.get 'content' > 0
      #location = todo.get('location').toLowerCase()
      @$(".jot-list").append view.render().el
    

    # Add all items in the **Todos** collection at once.
    addAll: ->
      window.Todos.each @addOne
    

    # Generate the attributes for a new Todo item.
    newAttributes: ->
      content: @input.val()
      order:   Todos.nextOrder()
      location: 'none'
   
    

    # If you hit return in the main input field, create new **Todo** model,
    # persisting it to *localStorage*.
    createOnEnter: (e) ->
      if e.keyCode is 13
        attrs = @newAttributes()
        attrs.content = @input.val()
        attrs.location = @currentDestination

        Todos.create attrs
        @input.val('')



  # Finally, we kick things off by creating the **App**.
  window.App = new AppView()


