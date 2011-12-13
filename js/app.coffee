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
			imageSearch.setResultSetSize 6	# equivalent to about 1 row

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
					img.attr 'width', img.data('width')
					img.attr 'height', img.data('height')
					img.data 'thumb-src', srcImage.attr('src')

					# load the real image off-screen and replace it when loaded
					largeImg = new Image()
					largeImg.onload = ->
						img.attr 'src', largeImg.src
					largeImg.src = srcImage.data 'src'


					# stash this away so we can get to it. gross.
					# workaround for http://bugs.jqueryui.com/ticket/7852
					# TODO see if we can attach additional data to the event / element
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

			_gaq.push(['_trackEvent', 'Search', 'Submit', q])
			
			
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

	cropEnable = true
	cropBorder = 0

	imageSize = null

	obj = {
		init: ->
			canvas = $('#canvas').get(0)
			ctx = canvas.getContext('2d')

			inst = this
			# TODO move out to a UI object
			jc = $('#canvas')

			for name in ['mousemove', 'mouseup', 'mousedown', 'dblclick']
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

		# returns the x/y for the event as offsetX and offsetY not available in all browsers.
		_getOffset: (event) ->
			x = null
			y = null

			if event.offsetX || event.offsetY
				x = event.offsetX
				y = event.offsetY
			else
				offset = $(event.target).offset()
				x = event.pageX - offset.left
				y = event.pageY - offset.top

			{ x:x, y:y }


		# gets the image hit by the event x,y or null
		_getHitImage: (event) ->
			offset = inst._getOffset event
			x = offset.x
			y = offset.y

			for img in images
				return img if x >= img.x and y >= img.y and x <= img.x + img.width and y <= img.y + img.height

			null

		dblclick: (event) ->
			img = inst._getHitImage event
			return if !img

			index = images.indexOf img
			images.splice index, 1

			inst.updateUI()
			inst.redraw()

		mousedown: (event) ->
			img = inst._getHitImage event
			if img
				dragImg = img
				offset = inst._getOffset event
				dragX = offset.x - img.x
				dragY = offset.y - img.y

		mousemove: (event) ->
			return if dragImg == null
			offset = inst._getOffset event
			dragImg.x = offset.x - dragX
			dragImg.y = offset.y - dragY
			inst.redraw()

		mouseup: ->
			dragImg = null
			inst.redraw()
		

		# dropped is the image dropped onto the canvas
		addImage: (dropped, x, y) ->
			# console.log dropped
			dropped = $(dropped)
			img = new APP.Canvas.Img dropped.attr('src'), dropped.data('src'), dropped.data('thumb-src'), dropped.data('width'), dropped.data('height'), x, y, ctx
			#console.log(img)

			img.scaleTo(imageSize) if imageSize

			images.push img

			this.updateUI()
			this.redraw()
			img.sanitize ctx

			_gaq.push(['_trackEvent', 'Canvas', 'Add', dropped.data('src')])


		# resizes all the images to a particular size
		resize: (size) ->
			imageSize = if size then size else canvas.width
			image.scaleTo(imageSize) for image in images
			this.redraw()

		crop: (border) ->
			cropBorder = if border then Math.max(parseInt(border), 0) else 0
			this.redraw()


		# updates UI after internal state changes
		updateUI: ->
			urls = []
			for image in images
				urls.push image.sourceUrl
			
			$('#image-sources').html(urls.join ', ')

			$('#download').attr 'disabled', (if images.length > 0 then null else 'disabled')

		# renders a clean canvas used to prompt the download
		download: ->
			dirty = []

			for image in images
				dirty.push image if image.dirty

			proceed = ->
				if dirty.length > 0
					img = dirty.shift()
					img.sanitize null, proceed
				else
					canvas2 = inst._drawCanvas()

					url = canvas2.toDataURL 'image/png'
					$('#result-image').attr('src', url)
					$('#result-container').show()

					_gaq.push(['_trackEvent', 'Canvas', 'Download', null, images.length])

					top = $('#result-image').position().top
					$('body').animate { scrollTop: top }, 600


			proceed()


		# clears and redraws the whole canvas to the screen
		redraw: ->
			ctx.clearRect 0, 0, canvas.width, canvas.height

			if images.length == 0
				ctx.save()
				ctx.textAlign = "center"
				ctx.font = "bold 28px Verdana"
				ctx.fillStyle = "#999"
				ctx.fillText "drop images here...", canvas.width / 2, 200
				ctx.restore()

				return

			info = this._calculateCanvas()

			# cropping border
			ctx.fillStyle = "#333"
			ctx.fillRect 0, 0, canvas.width, canvas.height

			ctx.fillStyle = "#fff"
			ctx.fillRect info.xMin, info.yMin, info.width, info.height
#			console.log ''+(xMin - b)+', '+(yMin - b)+', '+(xMax + b)+', '+(yMax + b)

			this._redraw ctx, canvas

			$('#image-size').html ''+info.width+'x'+info.height

		# provides the total bounding box of the rendered area relative to the overall canvas
		_calculateCanvas: ->
			xMin = canvas.width
			xMax = 0
			yMin = canvas.height
			yMax = 0

			for image in images
				xMin = Math.min xMin, image.x
				xMax = Math.max xMax, image.x + image.width
				yMin = Math.min yMin, image.y
				yMax = Math.max yMax, image.y + image.height
				#console.log 'image: '+image.width+', '+image.height

			b = if cropEnable then cropBorder else 0

			# note: if the user pushes the image off-screen it just draws them anyway
			xMin = xMin - b
			xMax = xMax + b
			yMin = yMin - b
			yMax = yMax + b

			width = xMax - xMin
			height = yMax - yMin

			{
				width: width
				height: height
				xMin: xMin
				xMax: xMax
				yMin: yMin
				yMax: yMax
				border: b
			}

		# draws the image onto a new, clean canvas and returns the canvas DOM element
		# meant for drawing a clean canvas the user can download
		_drawCanvas: ->
			info = this._calculateCanvas()
#			console.log info
			canvas2 = $(['<canvas width="',info.width,'" height="',info.height,'"></canvas>'].join('')).get(0)

			ctx2 = canvas2.getContext '2d'
			ctx2.clearRect 0, 0, canvas2.width, canvas2.height
			
			ctx2.fillStyle = "#fff"
			ctx2.fillRect 0, 0, info.width, info.height

			ctx2.save()
			ctx2.translate -info.xMin, -info.yMin
			this._redraw ctx2, canvas2
			ctx2.restore()

			canvas2			


		# draws images onto an arbitrary canvas.
		_redraw: (ctx, canvas) ->
			image.draw(ctx) for image in images


		# rearranges the images based on some preset
		rearrange: (arrangement) ->
			this.arrangements[arrangement]()
			this.redraw()

			_gaq.push(['_trackEvent', 'Canvas', 'Arrange', arrangement])


		# Calculations for arranging images in different ways
		arrangements: {
			_linear: (primaryName, primaryAxis, secondaryName, secondaryAxis)->
				canvasPrimary = canvas[primaryName]
				canvasSecondary = canvas[secondaryName]
				
				imagesTotal = 0
				for image in images
					imagesTotal += image[primaryName]
				
				padding = imagesTotal * .1
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
	cls = (src, sourceUrl, thumbSrc, width, height, x, y, ctx) ->
		this.safe = false	 # whether it's been pulled from a different origin
		# sourceUrl is only for source attribution and getting the original URL
		this.sourceUrl = sourceUrl
		this.thumbSrc = thumbSrc

		# means this image still uses the source URL
		this.dirty = true

		# note: these must always represent the rendered width/height of the image including scale
		this.width = this.origWidth = width
		this.height = this.origHeight = height

		this.x = x
		this.y = y
		this.scale = 1		# for constraining size

		# image drawn onto the canvas
		this._setSrc src, ctx

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

		# replaces the referenced image with one that can be downloaded
		sanitize: (ctx, callback) ->
			callback = callback || ->
			if !this.dirty
				callback()
				return

			inst = this
			src = this.sourceUrl
			#console.log 'cleaning: '+src
			$.getImageData {
				url: src
				success: (image) ->
					#console.log 'cleaned: '+src
					inst._setSrc image.src, ctx
					inst.dirty = false
					callback()
				
				error: (xhr, text_status) ->
					#console.log 'failed cleaning: '+text_status
					callback()
			}


		# changes the source of the image both creating a new underlying image instance and redrawing
		# change the Image object is important for canvas clean status
		_setSrc: (src, ctx) ->
			this.src = src
			this.img = img = new Image()
			this.loaded = false
			inst = this
			img.onload = -> 
				inst.loaded = true
				inst.draw(ctx) if ctx
			img.src = src


	cls
)()

# TODOs
# change static resource URLs to be CDN-ized
# fix the horizontal arrangement padding

# tighten up the overall styling on the page
# add some styling to the background / sections to separate the page
# add descriptive text to each section

# Future stuff
# Put in checkered background instead of solid crop border
# independently resizing images
# other arrangements: star, circle, etc
# when doing horizontal / vertical arrangement order them based on where they are on the canvas already
# adding a specific URL (image or page URL)
# searching by color
# add buttons restricting search by size (none, icon, small, medium)
# don't clean the same image multiple times based on url (whether it's in the image right now or not)
# change the canvas dimensions
# show / hide guides
# show / hide ruler
# allow aligning to a grid
# Ads
# when the page loads make the "lifter" animate upwards slowly
# opening the current image in pixlr

# Not doing
# add a spinner when results are loading (they are really fast...)
# Making the background transparent / non-white (for most images in the web this is useless and for most sites you'll put it on)
# allow setting image order via drag and drop (show icons next to each image) (useless feature)
# style the logo to be a custom font. perhaps something scripty.
# put in the background image for the initial load placeholder (just leaving the page as is)


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
	

	validate = (e, f) ->
		val = $(e).val()
		parent = $(e).closest('.clearfix')
		if val.match /^\d*$/
			parent.removeClass 'error'
			f val
		else
			parent.addClass 'error'

	$('#size').on "keyup", ->
		validate this, (val) -> APP.Canvas.resize val

	updateCrop = -> APP.Canvas.crop $('#crop-size').val()

	$('#crop-size').on "keyup", -> validate this, updateCrop

	# for analytics, we don't want to track events for every key press
	$('#size').change -> _gaq.push(['_trackEvent', 'Canvas', 'Resize', $(this).val()])
	$('#crop-size').change -> _gaq.push(['_trackEvent', 'Canvas', 'Crop', $(this).val()])


	updateCrop()
)
