jQuery ->
  # history view (right panel of classified info)
  class Railsjot.Views.HistoryView extends Backbone.View
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


  window.History = new Railsjot.Views.HistoryView()


