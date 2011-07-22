jQuery ->


  # Family History View

  class Railsjot.Views.FamilyHistoryView extends Backbone.View

    el:  ($ '.fh-container')
    tagName:  'div'
    template: JST["backbone/templates/fh_section"]

    # example family history
    fhistory:
      1: {code:'MGM', relationship: 'maternal grandmother', name: 'Ethel', age: 82, content: 'breast cancer, hypertension', deceased: true}
      2: {code:'MGF', relationship: 'maternal grandfather', name: 'Walter', age: 88, content: 'diabetes, tree nut allergy, gout', deceased: false}
      4: {code:'PGM', relationship: 'paternal grandmother', name: 'Penny', age: 75, content: 'in good health', deceased: false}
      5: {code:'PGF', relationship: 'paternal grandfather', name: 'Harold', age: 56, content: 'CAD, MIx2', deceased: true}
      3: {code:'M', relationship: 'mother', name: 'Nancy', age: '55', content: 'asthma, hypertension', deceased: false}
      6: {code:'F', relationship: 'father', name: 'Peter', age: 54, content: 'hypertension, hyperlipidemia', deceased: false}


    initialize: ->
      _.bindAll(this, 'render')
      $(@el).html @template({@fhistory})
      @


  window.FamilyHistoryView = new Railsjot.Views.FamilyHistoryView()



