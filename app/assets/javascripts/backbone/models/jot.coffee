
# Our basic **Jot** model has `content`, `order`, and `done` attributes.
class Railsjot.Models.Jot extends Backbone.Model

  EMPTY: ""
  idAttribute: '_id'

  initialize: ->
    unless @get "content"
      @set content: @EMPTY

  # Remove this Jot and delete its view.
  clear: -> 
    @destroy()
    @view.remove()


# Jot Collection
# ---------------

# The collection of jots is backed by *localStorage* instead of a remote
# server.
class Railsjot.Collections.JotList extends Backbone.Collection

  # Reference to this collection's model.
  model: Railsjot.Models.Jot

  url: '/jots'

  # We keep the Jots in sequential order, despite being saved by unordered
  # GUID in the database. This generates the next order number for new items.
  nextOrder: ->
    if (@length) then @last().get('order') + 1 else 1

  # Jots are sorted by their original insertion order.
  comparator: (jot) ->
    jot.get('order')


# Create our global collection of **Jots**.
window.Jots = new Railsjot.Collections.JotList()


