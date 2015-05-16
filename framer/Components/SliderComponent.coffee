Utils = require "../Utils"
{Layer} = require "../Layer"
{Events} = require "../Events"

"""
SliderComponent

knob <layer>
knobSize <width, height>
fill <layer>
min <number>
max <number>

pointForValue(<n>)
valueForPoint(<n>)

animateToValue(value, animationOptions={})
"""

class exports.SliderComponent extends Layer

	constructor: (options={}) ->
		options.backgroundColor ?= "#ccc"
		options.borderRadius ?= 50
		options.clip ?= false
		options.width ?= 300
		options.height ?= 10
		options.value ?= 0

		@knob = new Layer
			backgroundColor: "#fff"
			shadowY: 1, shadowBlur: 3
			shadowColor: "rgba(0,0,0,0.35)"

		@fill = new Layer 
			backgroundColor: "#333"
			width: 0, force2d: true

		super options

		@knobSize = options.knobSize or 30
		@knob.superLayer = @fill.superLayer = @

		@fill.height = @height
		@fill.borderRadius = @borderRadius

		@knob.draggable.enabled = true
		@knob.draggable.speedY = 0
		@knob.draggable.overdrag = false
		@knob.draggable.momentum = true
		@knob.draggable.momentumOptions = {friction: 5, tolerance: 0.25}
		@knob.draggable.bounce = false
		@knob.draggable.propagateEvents = false
		@knob.borderRadius = "50%"

		@_updateFrame()
		@_updateKnob()
		@_updateFill()

		@on("change:size", @_updateFrame)
		@on("change:borderRadius", @_setRadius)
		
		@knob.on("change:x", @_updateFill)
		@knob.on("change:size", @_updateKnob)

		@knob.on Events.Move, =>
			@_updateFrame()
			@_updateValue()

		# On click/touch of the slider, update the value
		@on(Events.TouchStart, @_touchDown)	
	
	_touchDown: (event) =>
		event.preventDefault()
		event.stopPropagation()

		offsetX = (@min / @canvasScaleX()) - @min
		@value = @valueForPoint(Events.touchEvent(event).clientX - @screenScaledFrame().x) / @canvasScaleX() - offsetX
		@knob.draggable._touchStart(event)
		@_updateValue()

	_updateFill: =>
		@fill.width = @knob.midX

	_updateKnob: =>
		@knob.midX = @fill.width		
		@knob.centerY()

	_updateFrame: =>
		@knob.draggable.constraints = 
			x: -@knob.width / 2
			y: -@knob.height / 2
			width: @width + @knob.width 
			height: @height + @knob.height
			
		@fill.height = @height
		@knob.centerY()
			
	_setRadius: =>
		radius = @borderRadius
		@fill.style.borderRadius = "#{radius}px 0 0 #{radius}px"
		
	@define "knobSize",
		get: -> @_knobSize
		set: (value) ->
			@_knobSize = value
			@knob.width = @_knobSize
			@knob.height = @_knobSize
			@knob.centerY()
			@_updateFrame()
	
	@define "min",
		get: -> @_min or 0
		set: (value) -> @_min = value

	@define "max",
		get: -> @_max or 1
		set: (value) -> @_max = value
		
	@define "value",
		get: -> @valueForPoint(@knob.midX)

		set: (value) -> 
			@knob.midX = @pointForValue(value)
			@_updateFill()

	_updateValue: =>
		@emit("change:value", @value)
	
	pointForValue: (value) ->
		return Utils.modulate(value, [@min, @max], [0, @width], true)
			
	valueForPoint: (value) ->
		return Utils.modulate(value, [0, @width], [@min, @max], true)
		
	animateToValue: (value, animationOptions={curve:"spring(300,25,0)"}) ->
		animationOptions.properties = {x:@pointForValue(value)}
		@knob.animate(animationOptions)