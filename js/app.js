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
  APP.Canvas = (function() {
    var ctx, obj;
    ctx = null;
    obj = {
      init: function() {
        ctx = $('#canvas').get(0).getContext('2d');
        return this.addImage('http://t2.gstatic.com/images?q=tbn:ANd9GcSSRIcB7epzREylpl1gQ6ZYo9Vw8iJA-DH9PrDYh5_8QrbwfNLDEZM-og', 10, 10);
      },
      addImage: function(src, x, y) {
        var img;
        img = new Image();
        img.onload = function() {
          return ctx.drawImage(img, x, y);
        };
        return img.src = src;
      }
    };
    $(function() {
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
