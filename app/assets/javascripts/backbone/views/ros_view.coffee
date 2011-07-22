jQuery ->
  # Review of systems View

  class Railsjot.Views.ROSView extends Backbone.View

    el:  ($ '.ros-container')
    tagName:  'div'
    template: JST["backbone/templates/ros_section"]

    initialize: ->
      _.bindAll(this, 'render')
      $(@el).html @template
      @


  window.Ros = new Railsjot.Views.ROSView()



