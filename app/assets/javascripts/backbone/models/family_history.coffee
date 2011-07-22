# Our basic **FamilyMember** model has `name`, `relationshipt`, `medical history`
class Railsjot.Models.FamilyMember extends Backbone.Model

  idAttribute: '_id'

  initialize: ->

  # Remove this Jot and delete its view.
  clear: -> 
    @destroy()
    @view.remove()


# FamilyMember Collection (FamilyHistory)
# ---------------

class Railsjot.Collections.FamilyHistory extends Backbone.Collection

  # Reference to this collection's model.
  model: Railsjot.Models.FamilyMember

  url: '/family_members'

  # We keep the Family_Members in sequential order, despite being saved by unordered
  # GUID in the database. This generates the next order number for new items.
  nextOrder: ->
    if (@length) then @last().get('order') + 1 else 1

  # Jots are sorted by their original insertion order.
  # comparator: (jot) ->
  #   jot.get('order')


# Create our global collection of **Family_Members (Family_History)**.
window.FamilyHistoryCollection = new Railsjot.Collections.FamilyHistory()


