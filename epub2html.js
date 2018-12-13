// JavaScript Document
jQuery.expr[':'].regex = function(elem, index, match) {
    var matchParams = match[3].split(','),
    validLabels = /^(data|css):/,
    attr = {
	method: matchParams[0].match(validLabels) ? 
	matchParams[0].split(':')[0] : 'attr',
	property: matchParams.shift().replace(validLabels,'')
    },
    regexFlags = 'ig',
    regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), regexFlags);
    return regex.test(jQuery(elem)[attr.method](attr.property));
};

jQuery.fn.outerHTML = function(s) {
    if (s) {
        return this.before(s).remove();
    } else {
        var doc = this[0] ? this[0].ownerDocument : document;
        return jQuery('<div>', doc).append(this.eq(0).clone()).html();
    }
};

(function($) {
    $.fn.closestPrior = function(selector) {
        selector = selector.replace(/^\s+|\s+$/g, "");
	console.log("selector: '"+selector+"'");
        var combinator = selector.search(/[ +~>]|$/);
	console.log("combinator: '"+combinator+"'");
        var parent = selector.substr(0, combinator);
		
	console.log("parent: '"+parent+"'");
        var children = selector.substr(combinator);
	console.log("children: '"+children+"'");
        var el = this;
	console.log("el: " + el.outerHTML());
        var match = $();
        while (el.length && !match.length) {
	    var savedel = el;
	    console.log("el: " + el.outerHTML());
	    console.log("el.prev(): " + el.prev().outerHTML());
            el = el.prev();
	    console.log("el: " + el.outerHTML());
            if (!el.length) {
                var par = savedel.parent();
                // Don't use the parent - you've already checked all of the previous 
                // elements in this parent, move to its previous sibling, if any.
                while (par.length && !par.prev().length) {
                    par = par.parent();
                }
                el = par.prev();
                if (!el.length) {
                    break;
                }
            }
	    console.log("comparing " + el.outerHTML() + " with " + parent);
	    console.log ("el.is(parent) is " + el.is(parent));
	    console.log ("el.find(children).length is " + el.find(children).length);
	    console.log ("el.find(selector).length is " + el.find(selector).length);
            if (el.is(parent) && el.find(children).length) {
		console.log("getting last child of " + el.outerHTML());
                match = el.find(children).last();
		console.log ("match found for " + this.outerHTML() + ": " + match.outerHTML());
            }
            else if (el.find(selector).length) {
		console.log("selecting last of '" + selector + "' within " + el.outerHTML() + "(" + el.find(selector).length + " items)");

                match = el.find(selector).last();
		console.log ("match found for " + this.outerHTML() + ": " + match.outerHTML());
            }
	    else if (el.is(selector))
		{
		    match = el;	
		    console.log ("match found for " + this.outerHTML() + ": " + match.outerHTML());
		}
        }
        return match;
    }
})(jQuery);


(function($) {
    $.fn.closestNext = function(selector) {
        selector = selector.replace(/^\s+|\s+$/g, "");
	console.log("selector: '"+selector+"'");
        var combinator = selector.search(/[ +~>]|$/);
	console.log("combinator: '"+combinator+"'");
        var parent = selector.substr(0, combinator);
		
	console.log("parent: '"+parent+"'");
        var children = selector.substr(combinator);
	console.log("children: '"+children+"'");
        var el = this;
	console.log(" el: " + el.outerHTML());
        var match = $();
        while (el.length && !match.length) {
	    var savedel = el;
            el = el.next();
	    console.log(" el: " + el.outerHTML());
            if (!el.length) {
                var par = savedel.parent();
                // Don't use the parent - you've already checked all of the previous 
                // elements in this parent, move to its previous sibling, if any.
                while (par.length && !par.next().length) {
                    par = par.parent();
                }
                el = par.next();
                if (!el.length) {
                    break;
                }
            }
	    console.log("comparing " + el.outerHTML() + " with " + parent);
	    console.log ("el.is(parent) is " + el.is(parent));
	    console.log ("el.find(children).length is " + el.find(children).length);
	    console.log ("el.find(selector).length is " + el.find(selector).length);
            if (el.is(parent) && el.find(children).length) {
		console.log("getting first child of " + el.outerHTML());
                match = el.find(children).first();
		console.log ("match found for " + this.outerHTML() + ": " + match.outerHTML());
            }
            else if (el.find(selector).length) {
		console.log("selecting first of '" + selector + "' within " + el.outerHTML() + "(" + el.find(selector).length + " items)");

                match = el.find(selector).first();
		console.log ("match found for " + this.outerHTML() + ": " + match.outerHTML());
            }
	    else if (el.is(selector))
		{
		    match = el;	
		    console.log ("match found for " + this.outerHTML() + ": " + match.outerHTML());
		}
        }
        return match;
    }
})(jQuery);

function testClosestPrior()
{
    var mycapt = $('#testcapt');
    console.log (mycapt.closestPrior('p.text').outerHTML());
};

// console.log = function() {};

function getTextWidth(textobj)
{
var	o = $('<div></div>').text(textobj.text()).css({'position': 'absolute', 'float': 'left', 'white-space': 'nowrap', 'visibility': 'hidden', 'font-family':textobj.css('font-family'),'font-weight':textobj.css('font-weight'),'font-size':textobj.css('font-size'),'font-style':textobj.css('font-style')}).appendTo($('body')),
      w = o.width();

  o.remove();

  return w;
}

function greatestTextWidth(objs)
{
	var greatest = 0;
	console.log("objs.length: " + objs.length);
	for (var i=0;i<objs.length;i++)
	{
		var w = getTextWidth(objs.eq(i));
		if (w > greatest) {greatest = w;}
	}
	return greatest;
}

function checkTextWidth (textobj,maxTextWidth,imgwrapper,imgwrapper2)
{
if (imgwrapper.attr('style') === undefined)
{
	console.log('imgwrapper has no style attribute');
	return imgwrapper;
}
var tw = getTextWidth(textobj);
console.log('text: ' + textobj.text() + ' text width: ' + tw);
if (tw > maxTextWidth) 
{
	imgwrapper2.append(imgwrapper.clone());
	console.log("imgwrapper2: " + imgwrapper2.outerHTML());
	imgwrapper.replaceWith(imgwrapper2);
	return imgwrapper2;
}
return imgwrapper; 	
}



function epub2html()
{
    //	alert("epub2html()");
    //	alert("pixcredits: " + $('.pixcredit').length + "\n" + 
    //	"captions: " + $('.captions').length + "\n" +
    //	"ccaptions: " + $('.ccaptions').length);

    layouts = $(':regex(class,_idgenObjectLayout.*)');
    // alert("_idgenObjectLayouts: " + layouts.length);
    for (var i = 0; i < layouts.length; i++){
	layouts.eq(i).attr("class","wide_image_c");
	layouts.eq(i).html(layouts.eq(i).html().replace('---------------------------------------------',''));
	var pixcredits = layouts.eq(i).find('.pixcredit');
	var titles = layouts.eq(i).find(':regex(class,figure-t.*)');
	var numbers = layouts.eq(i).find(':regex(class,figure-n.*)');
	var captions = layouts.eq(i).find('.captions');
	var ccaptions = layouts.eq(i).find('.ccaptions');
	var overviews = layouts.eq(i).find(':regex(class,.*overview.*|figure-units)');

	for (var k=0; k<titles.length; k++)
	    {var contents = titles.eq(k).contents();
		var newdiv = $("<div class='title'></div>");
		newdiv.append(contents);
		titles.eq(k).replaceWith(newdiv);}
	for (var k=0; k<numbers.length; k++)
	    {var contents = numbers.eq(k).contents();
		var newdiv = $("<div class='figure-number'></div>");
		newdiv.append(contents);
		numbers.eq(k).replaceWith(newdiv);}
	for (var k=0; k<pixcredits.length; k++)
	    {var contents = pixcredits.eq(k).contents();
		var newdiv = $("<div class='credit'></div>");
		newdiv.append(contents);
		pixcredits.eq(k).replaceWith(newdiv);
	    }
	for (var k=0; k<captions.length; k++)
	    {var contents = captions.eq(k).contents();
		var newdiv = $("<div class='caption'></div>");
		newdiv.append(contents);
		captions.eq(k).replaceWith(newdiv);
		}
	for (var k=0; k<ccaptions.length; k++)
	    {var contents = ccaptions.eq(k).contents();
		var newdiv = $("<div class='centered_caption'></div>");
		newdiv.append(contents);
		ccaptions.eq(k).replaceWith(newdiv);}
	for (var k=0; k<overviews.length; k++)
	    {var contents = overviews.eq(k).contents();
		var c = overviews.eq(k).attr("class");
		var str = "<div class='" + c + "'></div>";
		var newdiv = $(str);
		newdiv.append(contents);
		overviews.eq(k).replaceWith(newdiv);}

	
	var credits = layouts.eq(i).find('.credit');
	var titles = layouts.eq(i).find('.title');
	var numbers = layouts.eq(i).find('.figure-number');
	var capts = layouts.eq(i).find('.caption');
	var ccapts = layouts.eq(i).find('.centered_caption');
	// overviews go below the title, but above the first picture.
	var overviews = layouts.eq(i).find(':regex(class,.*overview.*|figure-units)');

				
						
						
	console.log("processing imgs in layout " + layouts.eq(i).outerHTML());

	console.log("---End of layout---");
	var imgs = layouts.eq(i).find('img');
	for(var j=0; j<imgs.length; j++)
	    {
		var imgclone = imgs.eq(j).clone();
		//alert ("layout " + i + " , image " + j + ": " + imgs.eq(j).attr('src') + "width: " + imgs.eq(j).prop('width'));


		console.log("processing img " + imgs.eq(j).outerHTML());
		/* if the image is not already hyperlinked, hyperlink it to itself and insert before it the text "View full size" */
		// var fslink = imgs.eq(j).parent();
		if (!imgs.eq(j).parent().is('a'))
		    {
			var fslink = $('<a href="' + imgs.eq(j).attr('src') + '" class="body_text">View full size<br /></a>');
			fslink.append(imgclone);
	 
	
	
					var imgwrapper = $('<div class="wide_image_c" style="max-width:' + imgs.eq(j).prop('width') + 'px"></div>');
				var imgwrapper2 = $('<div class="wide_image_c"></div>');
				
				imgwrapper.append(fslink);
				var imgwrapperMaxWidth = imgwrapper.css('max-width').slice(0,-2);

				console.log("imgwrapper: " + imgwrapper.outerHTML() + " imgwrapper max-width: " + imgwrapperMaxWidth);
				/* if text is more than 3 times the width of the image wrapper	then put the text outside the wrapper so it does not become a tall and narrow column
				*/
				var maxTextWidth = 3 * imgwrapperMaxWidth;

				imgs.eq(j).replaceWith(imgwrapper);
				console.log("imgs.eq(j).outerHTML: " + imgs.eq(j).outerHTML());

	 
	
			if (imgs.length > 1)
			    {
				for (var k=0; k<credits.length; k++)
				    {
					var cpimg = credits.eq(k).closestPrior('img');
					console.log ("comparing with " + cpimg.outerHTML());
					if (imgclone.attr('src') == cpimg.attr('src'))
					    {
						imgwrapper = checkTextWidth(credits.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.append(credits.eq(k));
						break;
					    }
				    }
				for (var k=0; k<ccapts.length; k++)
				    {
					// console.log("looking for closest img prior to " + ccapts.eq(k).outerHTML() + " whose parent is " + ccapts.eq(k).parent().outerHTML() + " and whose previous sibling is " + ccapts.eq(k).prev().outerHTML());
					var cpimg = ccapts.eq(k).closestPrior('img');
					console.log ("comparing with " + cpimg.outerHTML());
					if (imgclone.attr('src') == cpimg.attr('src'))
					    {
							imgwrapper = checkTextWidth(ccapts.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.append(ccapts.eq(k));
						break;
					    }
				    }
				for (var k=0; k<capts.length; k++)
				    {
					var cpimg = capts.eq(k).closestPrior('img');
					console.log ("comparing with " + cpimg.outerHTML());
					if (imgclone.attr('src') == cpimg.attr('src'))
					    {
							imgwrapper = checkTextWidth(capts.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.append(capts.eq(k));
						break;
					    }
				    }
				for (var k=0; k<overviews.length; k++)
				    {
					var cpimg = overviews.eq(k).closestNext('img');
					console.log ("comparing with " + cpimg.outerHTML());
					if (imgclone.attr('src') == cpimg.attr('src'))
					    {
							imgwrapper = checkTextWidth(overviews.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.prepend(overviews.eq(k));
						break;
						}
				    }

				for (var k=0; k<titles.length; k++)
				    {
					var cpimg = titles.eq(k).closestNext('img');
					console.log ("comparing with " + cpimg.outerHTML());
					if (imgclone.attr('src') == cpimg.attr('src'))
					    {
							imgwrapper = checkTextWidth(titles.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.prepend(titles.eq(k));
						break;
					    }
				    }
for (var k=0; k<numbers.length; k++)
				    {
					var cpimg = numbers.eq(k).closestNext('img');
					console.log ("comparing with " + cpimg.outerHTML());
					if (imgclone.attr('src') == cpimg.attr('src'))
					    {
							imgwrapper = checkTextWidth(numbers.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.prepend(numbers.eq(k));
						break;
					    }
				    }

		
			    }
			else
			    {
				console.log("lone image in layout: " + imgs.eq(j).outerHTML() + " to be replaced with " + fslink.outerHTML());
				for (var k=0; k<credits.length; k++)
				    {
						imgwrapper = checkTextWidth(credits.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.append(credits.eq(k));
						break;
				    }
				for (var k=0; k<ccapts.length; k++)
				    {
						imgwrapper = checkTextWidth(ccapts.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.append(ccapts.eq(k));
						break;
				    }
				for (var k=0; k<capts.length; k++)
				    {
						imgwrapper = checkTextWidth(capts.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.append(capts.eq(k));
						break;
				    }
				for (var k=0; k<overviews.length; k++)
				    {
						imgwrapper = checkTextWidth(overviews.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.prepend(overviews.eq(k));
						break;
				    }
				for (var k=0; k<titles.length; k++)
				    {
						imgwrapper = checkTextWidth(titles.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.prepend(titles.eq(k));
						break;
				    }
for (var k=0; k<numbers.length; k++)
				    {
						imgwrapper = checkTextWidth(numbers.eq(k),maxTextWidth,imgwrapper,imgwrapper2);
						imgwrapper.prepend(numbers.eq(k));
						break;
				    }			    }
		    }
	    }
	
    }
    //var locallinks = $('a:regex(href,^[\./])');
    var locallinks = $('a[href]').not(':regex(href,^[a-z]+://)').not('[href^="mailto:"]');
    console.log('Local links:')
	locallinks.each(function(){console.log("before: " + $(this).attr('href'));
		var str = $(this).attr('href');
		//console.log("str before: " + str);
		var newhref = str.replace('.xhtml','.html');
		//console.log("newhref after: " + newhref);
		$(this).attr('href', newhref);
		console.log("after: " + $(this).attr('href'));
	    });

    /*console.log('Non-local links:')
      var nonlocallinks = $('a:regex(href,^[a-z]+://)');
      nonlocallinks.each(function(){console.log($(this).attr('href'));});
      console.log('Email links:')
      var emaillinks = $('a[href^="mailto:"]');
      emaillinks.each(function(){console.log($(this).attr('href'));});
    */
    var mycontent = $('body').contents();
    $('<div id="convertedPage"></div>').appendTo('body');
    mycontent.appendTo('#convertedPage');

}