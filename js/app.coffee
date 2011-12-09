this.APP = APP = {}

# Handles performing the search
APP.Search = (->
	imageSearch = null
	imageTemplate = null
	
	searchSizes = null
	currentSize = null
	lastSearch = null

	obj = {
		init: ->
			# under the hood the presents send in an array of values. well, we don't want the defaults because small is only icons and medium has no icons and includes large images
			searchSizes = [["icon"], ["small"], ["medium"]]

			imageSearch = new google.search.ImageSearch()
			imageSearch.setSearchCompleteCallback this, this.handleResults, null
			imageSearch.setResultSetSize 6	# equivalent to 1 row

			imageTemplate = Handlebars.compile $('#image-template').html()

		handleResults: ->
			# todo: handle no results
			# TODO move out to a UI class
			$('#image-results .images').append imageTemplate(imageSearch.results)

			inst = this
			$('.image-result a').draggable({
				helper: ->
					# creates an image that is the full image to be dragged so it's more representative
					srcImage = $('img', this)
					img = srcImage.clone()
					img.attr 'src', srcImage.attr('data-src')
					img.data 'thumb-src', srcImage.attr('src')

					# stash this away so we can get to it					
					# workaround for http://bugs.jqueryui.com/ticket/7852
					inst.dropTarget = img.get(0)

					inst.dropTarget

				opacity: .6				
			})

			# TODO: only do this once
			google.search.Search.getBranding 'google-branding'

			# keep searching through the set sizes
			index = searchSizes.indexOf currentSize
			if index > -1 and index < searchSizes.length - 1
				currentSize = searchSizes[index + 1]	
				this.executeSearch()	
			

		executeSearch: ->
			# console.log currentSize
			imageSearch.setRestriction google.search.ImageSearch.RESTRICT_IMAGESIZE, currentSize

			imageSearch.execute lastSearch

		search: (q) ->
			# progressively get the images from smallest to biggest
			currentSize = searchSizes[0]
			lastSearch = q
			$('#image-results .images').empty()
			this.executeSearch()
			
			
	}

	google.load 'search', '1'
	google.setOnLoadCallback -> obj.init()

	obj
)()

# Maintains state and controls the canvas / drawing area
APP.Canvas = (->
	ctx = null
	canvas = null
	images = [] # images currently on the canvas

	dragImg =  null	# image being dragged
	dragX = null
	dragY = null

	inst = null

	obj = {
		init: ->
			canvas = $('#canvas').get(0)
			ctx = canvas.getContext('2d')

			inst = this
			# TODO move out to a UI object
			jc = $('#canvas')

			for name in ['mousemove', 'mouseup', 'mousedown']
				jc.bind name, inst[name]

			jc.droppable({
				accept: '.image-result a'
				activeClass: 'drop-highlight'
				drop: (event, ui) ->
					imgPos = ui.position
					canvasPos = $('#canvas').position()
					x = imgPos.left - canvasPos.left
					y = imgPos.top - canvasPos.top
					dropTarget = APP.Search.dropTarget
					src = $(dropTarget).attr('src')

					# console.log event
					inst.addImage dropTarget, x, y
			})

		mousedown: (event) ->
			# console.log event
			x = event.offsetX
			y = event.offsetY

			for img in images
				if x >= img.x and y >= img.y and x <= img.x + img.width and y <= img.y + img.height
					 dragImg = img
					 dragX = x - img.x
					 dragY = y - img.y

		mousemove: (event) ->
			return if dragImg == null
			dragImg.x = event.offsetX - dragX
			dragImg.y = event.offsetY - dragY
			inst.redraw()

		mouseup: ->
			dragImg = null
			inst.redraw()
		

		# dropped is the image dropped onto the canvas
		addImage: (dropped, x, y) ->
			# console.log dropped
			dropped = $(dropped)
			img = new APP.Canvas.Img dropped.attr('src'), dropped.data('thumb-src'), dropped.data('width'), dropped.data('height'), x, y, ctx
			#console.log(img)
			images.unshift img

			this.updateUI()
			this.redraw()

		# udpates UI after adding / removing images
		updateUI: ->
			urls = []
			for image in images
				urls.push image.sourceUrl
			
			$('#image-sources').html(urls.join ', ')


		download: ->
			Canvas2Image.saveAsPNG $('#canvas').get(0)

		# clears and redraws the whole canvas
		redraw: ->
			ctx.clearRect 0, 0, canvas.width, canvas.height
			image.draw(ctx) for image in images

		# rearranges the images based on some preset
		rearrange: (arrangement) ->
			this.arrangements[arrangement]()
			this.redraw()

		# resizes all the images to a particular size
		resize: (size) ->
			image.scaleTo(size) for image in images
			this.redraw()

		# Calculations for arranging images in different ways
		arrangements: {
			_linear: (primaryName, primaryAxis, secondaryName, secondaryAxis)->
				canvasPrimary = canvas[primaryName]
				canvasSecondary = canvas[secondaryName]
				
				imagesTotal = 0
				for image in images
					imagesTotal += image[primaryName]
				
				padding = imagesTotal * .2
				paddings = images.length - 1
				if padding + imagesTotal > canvasPrimary
					padding = Math.min((canvasPrimary - imagesTotal) / paddings, 5)
				
				imagesTotal += padding * paddings

				d = (canvasPrimary - imagesTotal) / 2
				for image in images
					image[primaryAxis] = d
					image[secondaryAxis] = (canvasSecondary - image[secondaryName]) / 2
					d += image[primaryName] + padding

			horizontal: ->
				this._linear 'width', 'x', 'height', 'y'

			vertical: ->
				this._linear 'height', 'y', 'width', 'x'

		}

	}

	$(-> obj.init())
	obj
)()

# Model for an image placed on the canvas
APP.Canvas.Img = (->
	cls = (src, thumbSrc, width, height, x, y, ctx) ->
		this.safe = false	 # whether it's been pulled from a different origin
		# sourceUrl is only for source attribution
		this.src = this.sourceUrl = src
		this.thumbSrc = thumbSrc

		# note: these must always represent the rendered width/height of the image including scale
		this.width = this.origWidth = width
		this.height = this.origHeight = height

		this.x = x
		this.y = y
		this.scale = 1		# for constraining size

		# image drawn onto the canvas
		this.img = img = new Image()
		this.loaded = false
		inst = this
		img.onload = -> 
			inst.loaded = true
			inst.draw(ctx)
		img.src = src

		this

	cls.prototype = 
		# draws itself onto the canvas
		draw: (ctx) ->
			ctx.save()
			ctx.scale(this.scale, this.scale) if this.scale != 1

			ctx.drawImage this.img, this.x / this.scale, this.y / this.scale if this.loaded
			ctx.restore()
			
		# scales the image to fit in a bounding box of this size
		scaleTo: (size) ->
			if size >= this.origWidth and size >= this.origHeight
				scale = 1
			else if this.origWidth > this.origHeight
				scale = size / this.origWidth
			else
				scale = size / this.origHeight

			this.scale = scale
			this.width = this.origWidth * scale
			this.height = this.origHeight * scale
			# console.log scale

	cls
)()

# TODOs
# put in the current image while the other is loading when dragging the image
# add a spinner when results are loading (they are really fast...)
# change the canvas dimensions
# add searching by color?
# download all the images
# add tooltip text to the controls
# remove images from the canvas
# opening the current image in pixlr
# adding a specific URL
# add auto-crop to put a bounding box around the images (checkbox?)
# add buttons restricting search by size (none, icon, small, medium)
# add validation to the resize box
# add GA integration
# track GA events for search

# allow setting image order via drag and drop (show icons next to each image)
# allow cropping the image
# show / hide guides
# show / hide ruler

# add some styling to the background / sections to separate the page
# color the number bubbles and put shadows on them
# style the logo to be a custom font. perhaps something scripty. make the "lifter" superscript.
# when the page loads make the "lifter" animate upwards slowly

# put some links in the header to me, twitter, and cantina
# add a credits section
# add descriptive text to each section


$(->
	$('#search-form form').submit((event) -> false)
	$('#q').on('keydown', (event) ->
		if (event.keyCode == 13)
			# TODO only search if it's different than the last search and not empty
			APP.Search.search $(this).val()

		#
		# hide the help
	)

	$('#download').click -> APP.Canvas.download()

	$('.topbar a.about').click -> 
		$('#about').slideToggle()
		false

	$('#about .close').click ->
		$('#about').slideToggle()
		false

	$('#arrangements').delegate 'button', 'click', ->
		APP.Canvas.rearrange $(this).data('arrangement')

	$('#resize').click -> APP.Canvas.resize $('#size').val()

	# seeing if this works...
	# $.getImageData {
	# 	url: "http://www.maths.nott.ac.uk/personal/sc/images/SteveC.jpg"
	# 	success: (image) ->
	# 		APP.Canvas.addImage image.src, 10, 10
		
	# 	error: (xhr, text_status) ->
	# }

)
