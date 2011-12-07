this.APP = APP = {}

APP.Search = (->
	imageSearch = null

	obj = {
		init: ->
			
			imageSearch = new google.search.ImageSearch()
			imageSearch.setSearchCompleteCallback this, this.handleResults, null

		handleResults: ->
			console.log imageSearch.results
			# todo: only do this once
			google.search.Search.getBranding 'google-branding'

		search: (q) ->
			imageSearch.execute q
			
	}

	google.load 'search', '1'
	google.setOnLoadCallback -> obj.init()

	obj
)()	

$(->
	$('#search-form form').submit((event) -> false)
	$('#q').on('keydown', (event) ->
		if (event.keyCode == 13)
			APP.Search.search $(this).val()

		#
		# hide the help
	)
)
