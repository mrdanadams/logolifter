(function() {
  var APP;
  this.APP = APP = {};
  APP.Search = (function() {
    var imageSearch, imageTemplate, obj;
    imageSearch = null;
    imageTemplate = null;
    obj = {
      init: function() {
        imageSearch = new google.search.ImageSearch();
        imageSearch.setSearchCompleteCallback(this, this.handleResults, null);
        return imageTemplate = Handlebars.compile($('#image-template').html());
      },
      handleResults: function() {
        $('#image-results .images').empty().append(imageTemplate(imageSearch.results));
        return google.search.Search.getBranding('google-branding');
      },
      search: function(q) {
        return imageSearch.execute(q);
      }
    };
    google.load('search', '1');
    google.setOnLoadCallback(function() {
      return obj.init();
    });
    return obj;
  })();
  $(function() {
    $('#search-form form').submit(function(event) {
      return false;
    });
    return $('#q').on('keydown', function(event) {
      if (event.keyCode === 13) {
        return APP.Search.search($(this).val());
      }
    });
  });
}).call(this);
