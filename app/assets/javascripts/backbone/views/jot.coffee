jQuery ->
  # Jot Item View
  # --------------

  # The DOM element for a jot item...
  class Railsjot.Views.JotView extends Backbone.View

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
      context = @model.get 'context'
      @$('.jot-content').text content
      @$('.context').text context
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


