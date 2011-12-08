this.APP = APP = {}

APP.Search = (->
	imageSearch = null
	imageTemplate = null
	

	obj = {
		init: ->
			imageSearch = new google.search.ImageSearch()
			imageSearch.setSearchCompleteCallback this, this.handleResults, null
			imageSearch.setResultSetSize 6	# equivalent to 1 row
			#imageSearch.setRestriction google.search.ImageSearch.RESTRICT_IMAGESIZE, google.search.ImageSearch.IMAGESIZE_MEDIUM

			imageTemplate = Handlebars.compile $('#image-template').html()

		handleResults: ->
			# todo: handle no results
			# TODO move out to a UI class
			$('#image-results .images').empty().append imageTemplate(imageSearch.results)

			$('.image-result a').draggable({
				helper: ->
					# creates an image that is the full image to be dragged so it's more representative
					img = new Image()
					img.src = $('img', this).data('src')
					img


				opacity: .6
				
			})

			# todo: only do this once
			google.search.Search.getBranding 'google-branding'

		search: (q) ->
			imageSearch.execute q
			
	}

	google.load 'search', '1'
	google.setOnLoadCallback -> obj.init()

	obj
)()

APP.Canvas = (->
	ctx = null

	obj = {
		init: ->
			canvas = $('#canvas')
			ctx = canvas.get(0).getContext('2d')

			inst = this
			# TODO move out to a UI object
			canvas.droppable({
				accept: '.image-result a'
				activeClass: 'drop-highlight'
				drop: (event, ui) ->
					imgPos = ui.position
					canvasPos = $('#canvas').position()
					x = imgPos.left - canvasPos.left
					y = imgPos.top - canvasPos.top
					src = $(event.target).attr('src')

					inst.addImage src, x, y
			})

		# TODO maintain a model that gets redrawn
		addImage: (src, x, y) ->
			img = new Image()
			img.onload = ->
				ctx.drawImage img, x, y

			img.src = src

		download: ->
			Canvas2Image.saveAsPNG $('#canvas').get(0)
	}

	$(-> obj.init())
	obj
)()

# TODOs
# pulse the canvas border opacity while you are dragging
# put in the current image while the other is loading when dragging the image
# add a spinner when results are loading (they are really fast...)
# add buttons restricting search by size (none, icon, small, medium)
# change the canvas dimensions
# add searching by color?
# download all the images

# allow setting image order via drag and drop (show icons next to each image)
# add text box for the dimensions to resize to (never size an image up)
# allow cropping the image
# allow arranging the images differently: star, circle, square, horizontal, vertical
# show / hide guides
# show / hide ruler

# add some styling to the background / sections to separate the page
# color the number bubbles and put shadows on them
# style the about box
# make the about link toggle, not show, the box
# put a close link in the about box
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
		$('#about').slideDown()
		false

	# seeing if this works...
	# $.getImageData {
	# 	url: "http://www.maths.nott.ac.uk/personal/sc/images/SteveC.jpg"
	# 	success: (image) ->
	# 		APP.Canvas.addImage image.src, 10, 10
		
	# 	error: (xhr, text_status) ->
	# }
)
