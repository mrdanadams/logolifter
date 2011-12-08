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
        $('.image-result a').draggable({
          helper: function() {
            var img;
            img = new Image();
            img.src = $('img', this).data('src');
            return img;
          },
          opacity: .6
        });
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
        var canvas, inst;
        canvas = $('#canvas');
        ctx = canvas.get(0).getContext('2d');
        inst = this;
        return canvas.droppable({
          accept: '.image-result a',
          activeClass: 'drop-highlight',
          drop: function(event, ui) {
            var canvasPos, imgPos, src, x, y;
            imgPos = ui.position;
            canvasPos = $('#canvas').position();
            x = imgPos.left - canvasPos.left;
            y = imgPos.top - canvasPos.top;
            src = $(event.target).attr('src');
            return inst.addImage(src, x, y);
          }
        });
      },
      addImage: function(src, x, y) {
        var img;
        img = new Image();
        img.onload = function() {
          return ctx.drawImage(img, x, y);
        };
        return img.src = src;
      },
      download: function() {
        return Canvas2Image.saveAsPNG($('#canvas').get(0));
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
    $('#q').on('keydown', function(event) {
      if (event.keyCode === 13) {
        return APP.Search.search($(this).val());
      }
    });
    $('#download').click(function() {
      return APP.Canvas.download();
    });
    return $.getImageData({
      url: "http://www.maths.nott.ac.uk/personal/sc/images/SteveC.jpg",
      success: function(image) {
        return APP.Canvas.addImage(image.src, 10, 10);
      },
      error: function(xhr, text_status) {}
    });
  });
}).call(this);
