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

function getImageDimensions(imageNode) {
  var source = imageNode.attr('src');
	console.log("getImageDimensions: source: " + source); 
  var imgClone = document.createElement("img");
  imgClone.src = source;
  return {width: imgClone.width, height: imgClone.height};
}

function greatestTextWidth(objs)
{
	var greatest = 0;
	console.log("objs.length: " + objs.length);
	for (var i=0;i<objs.length;i++)
	{
		var w = getTextWidth(objs[i]);
		console.log('width of '+objs[i].html()+': '+w);
		if (w > greatest) {greatest = w;}
	}
	return greatest;
}

function textTooWide (textobjs,maxTextWidth)
{
	var tw = greatestTextWidth(textobjs);
	return (tw > maxTextWidth) 
}
function adjustObjWidth(obj, objName)
{
	var objWidth = obj.width();
	var objOuterWidth = obj.outerWidth(true);
	var objPaddingBorderMargin = objOuterWidth - objWidth;
	var objParentWidth = obj.parent().width();
	if (objOuterWidth > objParentWidth)
	{	
		objWidth = objParentWidth - objPaddingBorderMargin;
		obj.width(objWidth);
	}
	var objWidthPct = (100 * objWidth / (objParentWidth - objPaddingBorderMargin)) + '%';
	obj.width(objWidthPct);
	console.log('width of '+ objName + ': '+obj.width()+'; changed to '+objWidthPct);
	
	return {num:objWidth, pct:objWidthPct};	
}
function getImageArrayWidth(imgs)
{
	var container = $('<div style="margin:0;padding:0;border:0;display:block;float:left;clear:none"></div>');
	// Make a clone of the image without its width and height attributes.
	for (var m = 0; m<imgs.length; m++)
	{
 		var imgClone = imgs.eq(m).clone();
		imgClone.css('max-width','none');
		imgClone.removeAttr('width');
		imgClone.removeAttr('height');
		container.append(imgClone);
	}
	container.appendTo($('body'));
	var w = container.width();
	//container.remove();
	return container.width();
}
function processImages(oac)
{
	var layouts = oac.find('table:has(img)');
    for (var i = 0; i < layouts.length; i++)
	{
		var tableWidth = adjustObjWidth(layouts.eq(i),'table '+i);
		layouts.eq(i).css({'margin':'0 auto'});
		var rows = layouts.eq(i).find('tr');
		console.log('table '+i+' has '+rows.length+' rows');
		for (var j = 0; j < rows.length; j++)
		{
			var columns = rows.eq(j).find('td, th');
			for (var k = 0; k < columns.length; k++)
			{
				console.log('Row '+j+', Column '+k+':');
				var imgs = columns.eq(k).find('img');
				// compute the combined width of the images in this cell when their height and width attributes are removed (exposing their natural height and width), as they are laid out according to their CSS styles.
				var maxImgWidth = getImageArrayWidth(imgs);
				console.log('maxImgWidth: '+maxImgWidth);
				var colWidth = adjustObjWidth(columns.eq(k),'table '+i+', row '+j+', column '+k);
				console.log('column width: '+colWidth.num+'('+colWidth.pct+')');
				var objs = columns.eq(k).contents();
				var textobjs = [];
				for(n=0;n<objs.length;n++)
				{
					var text = objs.eq(n).text();
					console.log('Row '+j+', Column '+k+':'+', object '+n+' text: "'+text+'"');
					if (text!==null && text.length > 0 && text.match(/\S/))
					{
						console.log('Row '+j+', Column '+k+':'+', object '+n+' contains text');
						//If the text is not more than 3 times the width of the image(s) in the same cell, limit the width of the text to the combined width of the images in the same cell
						if (getTextWidth(objs.eq(n)) <= 3*maxImgWidth)
						{objs.eq(n).css('max-width',maxImgWidth+'px');}
						textobjs.push(objs.eq(n));
					}
				}

				var maxWidth = 3*colWidth.num;
				console.log('max column width: '+maxWidth);

				if (tableWidth.pct != '100%' && textTooWide(textobjs,maxWidth))
				{
					layouts.eq(i).width('100%');
					console.log('table '+i+' widened to 100% to accomodate long text');	
				}
								
				if (imgs.length == 1)
				{ imgs.eq(0).width(null); imgs.eq(0).height(null); }
				else
				{
					for (var m = 0; m<imgs.length; m++)
					{
						adjustObjWidth(imgs.eq(m),'table '+i+', row '+j+', column '+k+', image '+m);	
						imgs.eq(m).removeAttr('width');					
						imgs.eq(m).removeAttr('height');					
					}
				}
			}
		}
	}
}

function processNRpage()
{
    $('#old_article_content').appendTo('#article_body');
	var oac = $('#old_article_content table tr td:has(p)').contents();
	$('#old_article_content').replaceWith(oac);
	$('font').replaceWith(function(){return $(this).contents();});
	processImages(oac);
	$('script').remove();
}