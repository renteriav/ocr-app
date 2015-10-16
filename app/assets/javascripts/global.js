$(document).ready(function(){
  /*
  var previewNode = document.querySelector("#template");
  previewNode.id = "";
  var previewTemplate = previewNode.parentNode.innerHTML;
  previewNode.parentNode.removeChild(previewNode);

  var myDropzone = new Dropzone(document.body, { // Make the whole body a dropzone
    paramName: "image",
    url: "run", // Set the url
    thumbnailWidth: 80,
    thumbnailHeight: 80,
    parallelUploads: 20,
    previewTemplate: previewTemplate,
    autoQueue: false, // Make sure the files aren't queued until manually added
    previewsContainer: "#previews", // Define the container to display the previews
    clickable: ".fileinput-button" // Define the element that should be used as click trigger to select files.
  });

  myDropzone.on("addedfile", function(file) {
    // Hookup the start button
    file.previewElement.querySelector(".start").onclick = function() { myDropzone.enqueueFile(file); };
  });

  // Update the total progress bar
  myDropzone.on("totaluploadprogress", function(progress) {
    document.querySelector("#total-progress .progress-bar").style.width = progress + "%";
  });

  myDropzone.on("sending", function(file) {
    // Show the total progress bar when upload starts
    document.querySelector("#total-progress").style.opacity = "1";
    // And disable the start button
    file.previewElement.querySelector(".start").setAttribute("disabled", "disabled");
  });

  // Hide the total progress bar when nothing's uploading anymore
  myDropzone.on("queuecomplete", function(progress) {
    document.querySelector("#total-progress").style.opacity = "0";
  });

  // Setup the buttons for all transfers
  // The "add files" button doesn't need to be setup because the config
  // `clickable` has already been specified.
  document.querySelector("#actions .start").onclick = function() {
    myDropzone.enqueueFiles(myDropzone.getFilesWithStatus(Dropzone.ADDED));
  };
  document.querySelector("#actions .cancel").onclick = function() {
    myDropzone.removeAllFiles(true);
  };*/
  

  Dropzone.options.dropzoneForm = {
    paramName: "image", // The name that will be used to transfer the file
    maxFilesize: 2, // MB
    success: function(file, response){
      
      if(response.status == 200){ // succeeded
        return file.previewElement.classList.add("dz-success"); // from source
      }else if (response.status !== 200){  //  error
        // below is from the source code too
        var node, _i, _len, _ref, _results;
        var message = response.message // modify it to your error message
        file.previewElement.classList.add("dz-error");
        _ref = file.previewElement.querySelectorAll("[data-dz-errormessage]");
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          _results.push(node.textContent = message);
        }
        return _results;
      }
    },
    error: function(file, message) {
      var node, _i, _len, _ref, _results;
      if (file.previewElement) {
        file.previewElement.classList.add("dz-error");
        if (typeof message !== "String" && message.error) {
          message = message.error;
        }
        _ref = file.previewElement.querySelectorAll("[data-dz-errormessage]");
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          _results.push(node.textContent = "error");
        }
        return _results;
      }
    }
  };
  
 // $("#").dropzone({ url: "/file/post" });
  /*
  $('#fileupload').fileupload({
      //dataType: 'script',
      url: 'run',
      acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i,
      add: function (e, data) {
  		 	$('#submit').click(function(event){
           event.preventDefault();
           data.submit();
  				 
  		 	});	              
  		 },
      sequentialUploads: true,
      autoupload: false
  });*/
  
  function getImageLightness(imageSrc,callback) {
      var img = document.createElement("img");
      img.src = imageSrc;
      img.style.display = "none";
      document.body.appendChild(img);

      var colorSum = 0;

      img.onload = function() {
          // create canvas
          var canvas = document.createElement("canvas");
          canvas.width = this.width;
          canvas.height = this.height;

          var ctx = canvas.getContext("2d");
          ctx.drawImage(this,0,0);

          var imageData = ctx.getImageData(0,0,canvas.width,canvas.height);
          var data = imageData.data;
          var r,g,b,avg;

          for(var x = 0, len = data.length; x < len; x+=4) {
              r = data[x];
              g = data[x+1];
              b = data[x+2];

              avg = Math.floor((r+g+b)/3);
              colorSum += avg;
          }

          var brightness = Math.floor(colorSum / (this.width*this.height));
          callback(brightness);
      }
  }
  /*
  $("#editor-window").imageEditor({ 
        'source': '/assets/user.png', 
        "maxWidth": 500, 
        "onClose": function () {
        }
  });
*/
  $.fn.cropper;
  $("#editor-window").on('click','#photoCanvas-wrapper', function(){
    $('#photoCanvas-wrapper > canvas').cropper({
      crop: function(e) {
        // Output the result data for cropping image.
        $('#x_cordinate').val(e.x);
        $('#y_cordinate').val(e.y);
        $('#width').val(e.width);
        $('#height').val(e.height);
      }
    });
  });
/*  
  $.fn.previewImage = function (imgContainer) {
     	var preview = $(imgContainer);

     	    this.change(function(event){
     	       var input = $(event.currentTarget);
     	       var file = input[0].files[0];
     	       var reader = new FileReader();
     	       reader.onload = function(e){
     	           image_base64 = e.target.result;
                 getImageLightness(image_base64,function(brightness){
                     console.log("brightness = " + brightness);
                     $('#brightness').val(brightness);
                 });
                 $(imgContainer).empty();
                 $(imgContainer).append('<img></img>');
     	           $(imgContainer + " img").attr("src", image_base64);
                 $('.container > img').cropper('destroy');
                 $.fn.cropper;
                 $('.container > img').cropper({
                   crop: function(e) {
                     // Output the result data for cropping image.
                     $('#x_cordinate').val(e.x);
                     $('#y_cordinate').val(e.y);
                     $('#width').val(e.width);
                     $('#height').val(e.height);
                   },
                   rotatable: false
                 });
                 /*
                 $("#editor-window").imageEditor({ 
                       'source': image_base64, 
                       "maxWidth": 500, 
                       "onClose": function () {
                       }
                 });
                 
     	       };
     	       reader.readAsDataURL(file);
             
             
     	    });
          
  };
  
  $('#image').previewImage(".container");
  
  */
});