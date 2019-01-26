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

function getContentWidth(obj, objName)
{
	var descendants = obj.find("*");
	console.log('getContentWidth: '+descendants.length+' descendants of '+objName+' found');
	var maxWidth = 0;
	for (var i=0; i<descendants.length; i++)
	{
		var w = descendants.eq(i).attr('width');
		if (w !== undefined && w > maxWidth)
		{
			console.log('getContentWidth: width of '+descendants.eq(i).outerHTML().substring(0,30)+': '+w);
			maxWidth = w;
		}
		else if ((w === undefined || w === 0) && descendants.eq(i).prop('tagName') === 'IMG')
		{
			w = getImageArrayWidth(descendants.eq(i));
			if (w > maxWidth) {maxWidth = w;}
		}
	}
	if (maxWidth > 0) {return maxWidth;}
	else {return obj.width();}
}

function adjustObjWidth(obj, objName,share_row)
// share_row is boolean: true if obj shares a cell or a row inside a table and should therefore be given a percentage width. Otherwise, its width attribute will be converted to a CSS max-width style
{
	var objWidth = obj.width();
	if (share_row && obj.attr('width') === undefined)
	{objWidth = getContentWidth(obj,objName);}

	//console.log(objName+' margin: '+obj.css('margin'));
	var objOuterWidth = obj.outerWidth();
	if (share_row) //include the margin
	{
		objOuterWidth = obj.outerWidth(true);
		if (objOuterWidth === 0) 
		{
		//	obj.attr('width','100%');
		//	objOuterWidth = obj.outerWidth(true);
			objOuterWidth = objWidth;
		}
	}
	console.log(objName+' outerWidth: '+objOuterWidth+' tagName: '+obj.prop("tagName"));
	var objPaddingBorderMargin = objOuterWidth - objWidth;
	var objParentWidth = obj.parent().width();
	if (objParentWidth === undefined)
	{
		objParentWidth = objOuterWidth;	
	}
	var objParentCode = obj.parent()[0].outerHTML.substring(0,30);
	console.log('objParent: '+objParentCode+ ' objParentWidth: '+objParentWidth);
	if (objOuterWidth > objParentWidth)
	{	
		objWidth = objParentWidth - objPaddingBorderMargin;
		obj.width(objWidth);
		console.log('adjusted objWidth: '+objWidth);
	}
	var objWidthPct = '100%';
	if (share_row)
	{
		if (objParentWidth > objPaddingBorderMargin)
		{
			objWidthPct = (100 * objWidth / (objParentWidth - objPaddingBorderMargin)) + '%';
		}
		obj.attr('width',objWidthPct);
		console.log('width of '+ objName + ': '+objWidth+'; changed to '+objWidthPct);
	}
	else if (obj.prop('tagName') === 'TABLE')
	{
		obj.css('max-width', '100%');
		obj.removeAttr('width');
	}
	else
	{
		obj.css('max-width', objWidth+'px');
		objWidth = 0;
		obj.removeAttr('width');
		console.log('width attribute of '+ objName + ' ('+objWidth+') replaced with CSS style attribute max-width');
	}
	
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
	container.remove();
	return w;
}
function processImages(layouts)
{
	console.log('layouts: '+ layouts.length);
	
    for (var i = 0; i < layouts.length; i++)
	{
		var tableWidth = adjustObjWidth(layouts.eq(i),'table '+i,false);
		layouts.eq(i).css({'margin':'0 auto'});
		var rows = layouts.eq(i).find('tr');
		console.log('table '+i+' has '+rows.length+' rows');
		var maxRowWidth = 0;
		for (var j = 0; j < rows.length; j++)
		{
			var rowWidth = 0;
			var columns = rows.eq(j).find('td, th');
			for (var k = 0; k < columns.length; k++)
			{
				console.log('Row '+j+', Column '+k+':');
				var imgs = columns.eq(k).find('img');
				console.log(imgs.length+' images found');
				if (imgs.length > 0)  //center the images
					{columns.eq(k).attr('align','center');}


				// compute the combined width of the images in this cell when their height and width attributes are removed (exposing their natural height and width), as they are laid out according to their CSS styles.
				var maxImgWidth = getImageArrayWidth(imgs);
				rowWidth += maxImgWidth;
				if (rowWidth > maxRowWidth) {maxRowWidth = rowWidth;}
				console.log('maxImgWidth: '+maxImgWidth);
				
				var colWidth = adjustObjWidth(columns.eq(k),'table '+i+', row '+j+', column '+k,true);
				console.log('column width: '+colWidth.num+'('+colWidth.pct+')');
	
				var objs = columns.eq(k).contents();
				var textobjs = [];
				for(var n=0;n<objs.length;n++)
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
				var maxMaxWidth = 3*maxRowWidth;
				console.log('max text length for this column: '+maxWidth);
				console.log('max text length for this table: '+maxMaxWidth);
				
				if (textTooWide(textobjs,maxMaxWidth))
				{
					layouts.eq(i).css('max-width','none');
					console.log('table '+i+' CSS max-width removed to accomodate long text');	
					//this attribute now required because the column has become wider than the image
					columns.eq(k).attr('align','center');
				}
	            else if (textTooWide(textobjs,maxWidth))
				{
					layouts.eq(i).css('max-width','maxRowWidth'+'px');
					console.log('table '+i+' CSS max-width adjusted to accomodate long text');	
					//this attribute now required because the column has become wider than the image
					columns.eq(k).attr('align','center');
				}
								
				if (imgs.length === 1)
				{ imgs.eq(0).removeAttr('width'); imgs.eq(0).removeAttr('height'); }
				else
				{
					for (var m = 0; m<imgs.length; m++)
					{
						adjustObjWidth(imgs.eq(m),'table '+i+', row '+j+', column '+k+', image '+m,true);	
						imgs.eq(m).removeAttr('width');				
						imgs.eq(m).removeAttr('height');					
					}
				}
				for (var m = 0; m<imgs.length; m++)
				{
					if (imgs.eq(m).parents('a').length === 0)
					{
						var src = imgs.eq(m).attr('src');
						var linkToSelf = $('<a href='+src+' title="View full size"></a>');
						imgs.eq(m).before(linkToSelf);
						linkToSelf.append(imgs.eq(m));
					}
				}
	
				if (rowWidth > maxRowWidth) {maxRowWidth = rowWidth;}
			}
			if (maxRowWidth > tableWidth.num) {tableWidth.num = maxRowWidth;}
		}
	
		if (layouts.eq(i).css('max-width') !== 'none')
		{
			layouts.eq(i).css('max-width',tableWidth.num+'px');
			console.log('table '+i+' CSS max-width set to '+tableWidth.num+'px to accomodate images');	
		}
		console.log('removing table width and height attributes and CSS');
		layouts.eq(i).css('width', 'auto');
		layouts.eq(i).css('height', 'auto');
		layouts.eq(i).removeAttr('width');
		layouts.eq(i).removeAttr('height');
	}
}

(function($) {
    $.fn.replaceFontTag = function (bodyFontSize) {
		var size = this.attr('size');
		if (size !== '-1') 
		{
			return this.contents();	
		}
		else
		{
			var bodyFontSizeNumber = bodyFontSize.match(/^\d+/);
			var bodyFontSizeUnits = bodyFontSize.match(/[a-z]+$/i);
			var newMinus1Size = (0.8*bodyFontSizeNumber) + bodyFontSizeUnits;
			//console.log('newMinus1Size: '+newMinus1Size);
			var newTag = $('<span></span>');
			newTag.css('font-size',newMinus1Size);
			newTag.css('line-height','normal');
			newTag.append(this.contents());
			return newTag;
		}	
	};
})(jQuery);

function processNRpage()
{
	//console.log('processNRpage');
	// #old_article_content contains the entire contents of the body tag of the original page. #article_body is the container for the article content in the template from which the new, responsive page is to be generated.
    $('#old_article_content').appendTo('#article_body');
	// select the first table cell from #old_article_content that contains a p tag.  This should be the cell that contains the article content.  If that cell is found, replace #old_article_content with the content of that cell.  #article_body now contains the old article's content.  If that cell is not found, insert a comment at the beginning of the document to alert the perl script that this page is defective and should not be posted on the website.
	var oac = $('#old_article_content table tr td:has(p)').eq(0);
	console.log('oac.length: '+oac.length);
	if (oac.length === 0)
	{
		$('html').prepend('<!-- old article content table cell not found -->');
		// shorten the file to be written, since it's going to be deleted.  Delete 'head' last because it contains a reference to this script.
//		$('body').remove();  
//		$('head').remove();  
//		return;
	}
	//console.log('oac length: '+oac.length);
	else
	{
		$('#old_article_content').replaceWith(oac.contents());
	}
	var bodyFontSize = $('body').css('font-size');
	var fontTags = $('font');
	for (var p=0; p<fontTags.length; p++)
	{
		var replacement = fontTags.eq(p).replaceFontTag(bodyFontSize);
		fontTags.eq(p).replaceWith(replacement);
	}
	var layouts = $('#article_body').find('table:has(img)');

	if (oac.length === 0)
	{
		layouts = $('#old_article_content').find('table:has(img)');
	}
	processImages(layouts);
	
	var freeImages = $('#article_body').find('img[width]');
	if (oac.length === 0)
	{
		freeImages = $('#old_article_content').find('img[width]');
	}
	
	//console.log('free images :'+freeImages.length);
	//free images are those not contained in a table cell.  Here we strip them of width and height attributes and center them in a containing div.  Since the default img css is max-width:100%, the image will display horizontally centered and at its native dimensions if the container is wide enough or more than wide enough; otherwise, the picture will shrink proporionally, maintaining aspect ratio, to fit its container.  The container's height is automatically calculated from the height of its content, one image.
	for (var n=0; n<freeImages.length; n++)
	{
		freeImages.eq(n).removeAttr('width');
		freeImages.eq(n).removeAttr('height');
		freeImages.eq(n).css('margin','0 auto');
		var fiContainer = $('<div style="width:100%; text-align:center"></div>');
		freeImages.eq(n).before(fiContainer);
		fiContainer.append(freeImages.eq(n));
	}
	$('script').remove();
}