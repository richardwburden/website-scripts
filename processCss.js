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


function getCharOverrides() {
    var classes = {};
	
    // Extract the stylesheets
    return Array.prototype.concat.apply([], Array.prototype.slice.call(document.styleSheets)
        .map(function (sheet) {
		//	console.log('sheet.href: ' + sheet.href);
		/* skip over stylesheet with name ending '_0.css', which never contains character style overrides. */
			if (sheet.href.match(/_0\.css$/)) return;
            if(null == sheet || null == sheet.cssRules) return;
            // Extract the rules
            return Array.prototype.concat.apply([], Array.prototype.slice.call(sheet.cssRules)
                .map(function(rule) {
			//		console.log(rule.selectorText);
					var override = rule.selectorText.match(/span\.CharOverride\-\d+/g);
					if (override !== null)
					{
						override[0] = override[0].substr(5);
					}
					else
					{return;}
				//	console.log(override);
                    // Grab a list of classNames from each selector
                    return override || [];
                })
            );
        })
    ).filter(function(name) {
        // Reduce the list of classNames to a unique list
        return !classes[name] && (classes[name] = true);
    });
}

function processCss()
{
	var stylenames = ['bo','it','sup','sub','ns','nw','sc','uc','lc'];
	var stylevals = {};
	for (var i=0;i<stylenames.length;i++)
	{
		stylevals[stylenames[i]] = stylenames[i] + ';';	
	}
//	console.log(stylevals);
	var CharOverrideText = '';
	var CharOverrides = getCharOverrides();
//	console.log(CharOverrides);
 	for (var i=0; i<CharOverrides.length;i++)
	{
		if (typeof CharOverrides[i] === "undefined") {continue;}
//		console.log ('CharOverrides[' + i + '] = ' + CharOverrides[i]);
		var cnum = CharOverrides[i].replace('CharOverride-','');
 //       console.log ('cnum: ' + cnum);
		var span = $('<span class="' + CharOverrides[i] + '"></span>');
		$('body').prepend(span);
//		console.log (span);
		var fw = span.css('font-weight');
//		console.log(fw);
		var fs = span.css('font-style');
//		console.log(fs);
		var tt = span.css('text-transform');
//		console.log(tt);
		var ff = span.css('font-family');
		var fv = span.css('font-variant');
//		console.log(fv);
		var va = span.css('vertical-align');
//		console.log(va);
		var ns = true;
		var nw = true;
		if (fw == 'bold' || fw > 500 || ff.match(/demi|bold/i))
		{
			nw = false;
			stylevals['bo'] += cnum + ',';
		}
		if (fs == 'italic' || ff.match(/italic/i)) 
		{
			ns = false; 
			stylevals['it'] += cnum + ',';
		}

		/* test whether the computed style will remain normal style when the span tag is wrapped by <em>.  This would indicate that the css rule for this character style override is explicitly font-style:normal and that the font family does not match /italic/i */
		var ittag = $('<em></em>');
		ittag.append(span);
		$('body').prepend(ittag);
		fs = span.css('font-style');
		console.log(fs);
		if (fs != 'normal') {ns = false;}
	
		/* test whether the computed font weight will remain normal when the span tag is wrapped by <strong>.  This would indicate that the css rule for this character style override is explicitly font-weight:normal or font-weight:N where N <= 500 and that the font family does not match /demi|bold/i  */
		var strongtag = $('<strong></strong>');
		strongtag.append(span);
		$('body').prepend(strongtag);
		fw = span.css('font-weight');
		console.log(fw);
		if (fw == 'bold' || fw > 500) {nw = false;}

		if (ns) {stylevals['ns'] += cnum + ',';} 
		if (nw) {stylevals['nw'] += cnum + ',';} 
		
		/* clean-up */
		ittag.remove();
		strongtag.remove();
		
		if (tt == 'uppercase') {stylevals['uc'] += cnum + ',';}
		if (tt == 'lowercase') {stylevals['lc'] += cnum + ',';}
		if (fv == 'small-caps') {stylevals['sc'] += cnum + ',';}

		if (va == 'super')
		{stylevals['sup'] += cnum + ',';}
		if (va == 'sub')
		{stylevals['sub'] += cnum + ',';}

		// console.log('ff: ' + ff);
/* The user may specify how a particular character style override is to be handled by editing the CSS file, adding '_XX_' to the beginning of the font-family for that style (adding a font-family if there is none), where XX is any character style override type recognized by eir2epub.pl, e.g. 'h1' for the 'h1_class', 'sf' for the 'sf_class'   */		
		var ffprefix = ff.match(/^"?_[^_]*_/);
		// console.log('ffprefix: ' + ffprefix);
		if (ffprefix !== null)
		{
			var ffp = ffprefix[0].slice(1,-1);
			// console.log('ffp: ' + ffp);
			if (ffp.slice(0,1) == '_') {ffp = ffp.slice(1);}
			// console.log('ffp: ' + ffp);
			if (typeof stylevals[ffp] === 'undefined')
			{
				stylevals[ffp] = ffp + ';';
				stylenames.push(ffp);
			}
			stylevals[ffp] += cnum + ',';
		}
	}
	// console.log(stylevals);
	for (var i=0;i<stylenames.length;i++)
	{
		if (stylevals[stylenames[i]] == stylenames[i] + ';')
		{continue;}
		if (stylevals[stylenames[i]].slice(-1) == ',')
		{stylevals[stylenames[i]] = stylevals[stylenames[i]].slice(0,-1);}
		CharOverrideText += stylevals[stylenames[i]] + ';';	
	}
	if (CharOverrideText.slice(-1) == ';')
	{CharOverrideText = CharOverrideText.slice(0,-1);}

	$('body').prepend('<div id="CharOverrides">' + CharOverrideText + '</div>');
}