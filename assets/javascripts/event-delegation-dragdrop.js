// Copyright (c) 2005-2007 Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)
//           (c) 2005-2007 Sammi Williams (http://www.oriontransfer.co.nz, sammi@oriontransfer.co.nz)
//           (c) 2007 Peter Bex, Solide ICT (http://www.solide-ict.nl)
//
// script.aculo.us is freely distributable under the terms of an MIT-style license.
// For details, see the script.aculo.us web site: http://script.aculo.us/

if(typeof Effect == 'undefined')
  throw("dragdrop.js requires including script.aculo.us' effects.js library");

Element.findDeepest = function(elements) {
  var deepest = elements[0];

  for (i = 1; i < elements.length; ++i)
    if (elements[i].descendantOf(deepest))
      deepest = elements[i];

  return deepest;
};

Element.addMethods({
  depth : function(element, root) {
    var depth;
    for (depth = 0; element != root; element = element.parentNode, depth++);
    return depth;
  },

  // This would be nice to have in Prototype, but it's not yet generic enough for that.
  // To get this, we also need right and bottom and maybe some other stuff I haven't thought of.
  makePixelPositioned : function(element) {
    var top = element.getStyle('top') || '0px';
    var left = element.getStyle('left') || '0px';
    var margintop = element.getStyle('margin-top') || '0px';
    var marginleft = element.getStyle('margin-left') || '0px';
    var parentdim = $(element.parentNode).getDimensions();
    if (top.indexOf('%') > 0)
      top = Math.round((parseFloat(top) / 100.0) * parentdim.height);
    else
      top = parseInt(top);
    if (margintop.indexOf('%') > 0)
      margintop = Math.round((parseFloat(margintop) / 100.0) * parentdim.height);
    else
      margintop = parseInt(margintop);

    if (left.indexOf('%') > 0)
      left = Math.round((parseFloat(left) / 100.0) * parentdim.width);
    else
      left = parseInt(left);
    if (marginleft.indexOf('%') > 0)
      marginleft = Math.round((parseFloat(marginleft) / 100.0) * parentdim.width);
    else
      marginleft = parseInt(marginleft);
    element.setStyle({left: left + 'px', top: top + 'px', marginLeft: marginleft+'px', marginTop: margintop+'px'});
  }
});

var Droppable = Class.create();
Object.extend(Droppable, {
  drops: [],
  register: function(droppable) {
    this.drops.push(droppable);
  },
  unregister: function(droppable) {
    this.drops = this.drops.without(droppable);
  },
  update: function(draggable, event) {
    var acceptersHash = {};
    var accepters = [];
    Position.prepare();
    var el = null;
    this.drops.each(function(d) {
      if (d.accepts(draggable, event) && (el = d.options.findElement(d.element, draggable, d, point)) &&
          Position.within(el, point[0], point[1])) {
        acceptersHash[el] = d;
        accepters.push(el);
      }
    });

    var targetElement = Element.findDeepest(accepters);
    var target = acceptersHash[targetElement];
    if (this._lastActive && this._lastActive != target)
      this._lastActive.deactivate(draggable, event);

    this._lastActive = target;
    if (target) {
      if (target._dropping)
        target.update(draggable, targetElement, event);
      else
        target.activate(draggable, targetElement, event);
    }
  },
  notifyDrop: function(draggable, event) {
    this.drops.each(function(d) { d.notifyDrop(draggable, [Event.pointerX(event), Event.pointerY(event)]); });
    this._lastActive = null;
  },

  /* Generic findElement function for droppables based on depth of the node */
  findElementDepth: function(lowest, highest) {
    return function(element, draggable, droppable, point) {
      element = droppable.element;
      for(var lvl=0; (!lowest || (lowest <= lvl)) && (!highest || (lvl < highest)); lvl++) {
        var sub = element.immediateDescendants().select(function(d) {
          return (d != draggable._dragging && d != draggable._clone && Position.within(d, point[0], point[1]));
        });
        if (sub.length == 0) {
          if (lowest && lvl <= lowest)  // lower allowed?
            return false;
          else
            return element;
        }
        element = sub[0];  // If there are more, tough shit :)
        // Maybe select the one with highest z-index which is visible etc, etc...?)
        // Anyway, this current code matches that of old Scriptaculous dragdrop
      }

      return element;
    };
  },
  /* Generic findElement function for droppables that returns the the deepest element that has any of the given classnames */
  findElementClass: function() {
    var classnames = $A(arguments);
    return function(element, draggable, droppable, point) {
      var deepest = false;
      element = droppable.element;
      while(true) {
        if (classnames.any(Element.hasClassName.curry(element)))
          deepest = element;
        var sub = element.immediateDescendants().select(function(d) {
          return (d != draggable._dragging && d != draggable._clone && Position.within(d, point[0], point[1]));
        });
        if (sub.length == 0)
          return deepest;
        else
          element = sub[0];
      }
    };
  }
});
Droppable.prototype = {
  initialize: function(element, options) {
    this.element = $(element);
    this._dropping = false;
    this.options = Object.extend({
      hoverStyle: {},      // Style to apply while draggable hovers over it
      hoverClass: false,   // Class to apply while draggable hovers over it
      accept: false,       // List of classes for draggables this droppable accepts.  If false, accept all
      acceptOk: true,      // Boolean or function(draggable, droppable, pos) => boolean that decides if draggable is acceptable
      onDrop: false,       // Function(draggable, droppable, pos) to call when draggable is dropped
      onEnter: false,      // Function(draggable, droppable, pos, element) to call when draggable enters droppable area
      onLeave: false,      // Function(draggable, droppable, pos) to call when draggable leaves droppable area
      onHover: false,      // Function(draggable, droppable, pos) to call when draggable is moved while hovering
      onChangeElement: false, // Function(draggable, droppable, pos, element) to call when mouse now hovers over a different element
      findElement: this.findElement.bind(this) // Function(element, draggable, droppable, pos) => (element or false) that decides which element to drop on
    }, options || {});
    if (this.options.accept)
      this.options.accept = [this.options.accept].flatten();
    Droppable.register(this);
  },
  findElement: function(element) {
    return this.element;
  },
  destroy: function() {
    Droppable.unregister(this);
  },
  markActive: function(element) {
    this._oldHoverStyle = {};
    for (var s in this.options.hoverStyle)
      this._oldHoverStyle[s] = element.getStyle(s);
    element.setStyle(this.options.hoverStyle);

    if (this.options.hoverClass)
      element.addClassName(this.options.hoverClass);
    this._dropping = element;
  },
  activate: function(draggable, element, event) {
    var point = [Event.pointerX(event), Event.pointerY(event)];
    this.markActive(element);

    if (this.options.onEnter)
      this.options.onEnter(draggable, this, point);
    draggable.notifyEnter(this, point, element);
  },
  markInactive: function() {
    if (this.options.hoverClass)
      this._dropping.removeClassName(this.options.hoverClass);
    this._dropping.setStyle(this._oldHoverStyle);
    this._dropping = false;
  },
  deactivate: function(draggable, event) {
    var point = [Event.pointerX(event), Event.pointerY(event)];

    if (this.options.onLeave)
      this.options.onLeave(draggable, this, point);

    draggable.notifyLeave(this, point);
    this.markInactive();
  },
  update: function(draggable, element, event) {
    var point = [Event.pointerX(event), Event.pointerY(event)];

    if (this._dropping != element) {
      if (this._dropping)
        this.markInactive();
      this.markActive(element);
      if (this.options.onChangeElement)
        this.options.onChangeElement(draggable, this, point, element);
    }

    if (this.options.onHover)
      this.options.onHover(draggable, this, point);
  },
  accepts: function(draggable, event) {
    point = [Event.pointerX(event), Event.pointerY(event)];
    /* Position.prepare() has been called by Droppable.update */
    return (draggable._dragging != this.element &&
            !this.element.descendantOf(draggable._dragging) &&
            (!this.options.accept || this.options.accept.any(Element.hasClassName.curry(draggable._dragging))) &&
            (this.options.acceptOk == true ||
             (typeof(this.options.acceptOk) == "function" &&
              this.options.acceptOk(draggable, this, point))));
  },
  notifyDrop: function(draggable, point) {
    if (!this._dropping)
      return;
    if (this.options.onDrop)
      this.options.onDrop(draggable, this, point);
    draggable.notifyDrop(this, point);
    this.markInactive();
  }
};

/*--------------------------------------------------------------------------*/

var Draggable = Class.create();
Object.extend(Draggable, {
  makeSolid: function(element, draggable) {
    var toOpacity = typeof element._opacity == 'number' ? element._opacity : 1.0;
    new Effect.Opacity(element, {duration:0.2, from:0.7, to:toOpacity,
                                 queue: {scope:'_draggable', position:'end'}});
  },
  makeTransparent: function(element, draggable) {
    draggable._opacity = Element.getOpacity(element);
    new Effect.Opacity(element, {duration:0.2, from:draggable._opacity, to:0.7});
  },
  snapBack: function(element, draggable, top_offset, left_offset) {
    var dur = Math.sqrt(Math.abs(top_offset^2)+Math.abs(left_offset^2))*0.02;
    new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: dur,
                               queue: {scope:'_draggable', position:'end'}
                             });
  },
  /* Generic findElement function for Draggables based on depth */
  findElementDepth: function(lowest, highest) {
    return function(element, draggable, droppable, point) {
      if (!highest && !lowest)      // Don't care about depth?  Then just return this element.
        return element;

      var el = element;
      var depth = element.depth(draggable.element);

      if (lowest && depth < lowest)
        return false;

      if (!highest)
        return element;

      for (; depth > highest; depth--, element = element.parentNode);

      return element;
    };
  },
  /* Generic findElement function for Draggables based on classnames */
  findElementClass: function() {
    var classnames = $A(arguments);
    return function(element, draggable) {
      for (; element != draggable.element; element = element.parentNode) {
        if (classnames.any(Element.hasClassName.curry(element)))
          return element;
      }
      return false;
    };
  },
  illegalTags: ['INPUT', 'SELECT', 'OPTION', 'BUTTON', 'TEXTAREA']  // tags that should never be dragged
});
Draggable.prototype = {
  initialize: function(element, options) {
    this.element = $(element);
    this.options = Object.extend({
      dragStyle: {zIndex: '1000'},  // Style to apply while dragging
      dragClass: false,     // Class to apply while dragging
      delay: false,         // Number or false, indicating nr of milliseconds to wait before starting the drag
      handleClass: false,   // class of a drag handle.  Element can only be dragged by this.  Override findElement for more fine-grained control.
      hoverStyle: {},       // Style to apply while hovering over a droppable
      hoverClass: false,    // Class to apply while hovering over a droppable
      findElement: this.findElement, // Function(element, draggable) => (element or false) that decides which element to drag
      scrollSpeed: 15,      // Array [x, y] representing number of pixels to scroll in x/y directions per 10 milliseconds.  can also be a number
      scrollSensitivity: 20,// Array [x, y] representing number of pixels from the top/bottom at which point scrolling will start.  can also be a number
      onStart: false,       // Function(element, draggable) that gets called when dragging is initiated
      onEnd: false,         // Function(element, draggable) that gets called when dragging is ended
      onEnter: false,       // Function(droppable, draggable, pos) that gets called when draggable first moves over droppable
      onLeave: false,       // Function(droppable, draggable, pos) that gets called when draggable moves out of droppable
      onDrag: false,        // Function(droppable, draggable, pos) that gets called when moving
      onDrop: false,        // Function(droppable, draggable, pos) that gets called when dropped on a droppable that accepts the draggable
      constraint: false,    // 'horizontal' or 'vertical' if the draggable can only be dragged over that axis
      revert: false,        // Function(element, draggable) -> boolean or boolean that decides if the element should revert to its original position
      startEffect: (function() {    // Function(element, draggable) that gets called when dragging is initiated, for a visual effect
        /* startEffect is only a function if there is no endEffect defined by the user */
        if (!options || !options.endEffect)
          return Draggable.makeTransparent;
        else
          return false;
      })(),
      endEffect: Draggable.makeSolid,    // Function(element, draggable) that gets called when dragging is stopped
      revertEffect: Draggable.snapBack,  // Function(element, draggable, top, left) that gets called to revert to the original position.
      illegalTags: Draggable.illegalTags // An array of tagnames that should never be draggable
    }, options || {});

    if (!(this.options.scrollSpeed instanceof Array))
      this.options.scrollSpeed = [this.options.scrollSpeed, this.options.scrollSpeed];
    if (!(this.options.scrollSensitivity instanceof Array))
      this.options.scrollSensitivity = [this.options.scrollSensitivity, this.options.scrollSensitivity];

    this.onMouseDown = this.startDrag.bindAsEventListener(this);
    this.onMouseMove = this.updateDrag.bindAsEventListener(this);
    this.onMouseUp = this.endDrag.bindAsEventListener(this);
    Event.observe(this.element, 'mousedown', this.onMouseDown);
  },

  findElement: function(element, draggable) {
    if (draggable.options.illegalTags.include(element.tagName.toUpperCase()) ||
       (draggable.options.handleClass && !element.hasClassName(draggable.options.handleClass)))
      return false;
    else
      return draggable.element;
  },

  destroy: function() {
    Event.stopObserving(this.element, "mousedown", this.onMouseDown);
  },

  startDrag: function(event) {
    // When switching tabs, releasing button, then switching and pressing button,
    // this situation can occur.  Just punt.
    if (this._dragging || this._timeout)
      return;

    var tgt = this.options.findElement(Event.element(event), this);

    if (!tgt)
      return;

    this._dragging = tgt;
    var point = [Event.pointerX(event), Event.pointerY(event)];
    Event.stop(event);

    Event.observe(document, 'mouseup', this.onMouseUp);

    if (this.options.delay)
      this._timeout = setTimeout(function() {
        this._timeout = null;
        this.initDrag(point);
      }.bind(this), this.options.delay);
    else
      this.initDrag(point);
  },

  initDrag: function(point) {
    /* This part below implements ticket #8369, it ensures percentage positioning works */
    this._dragging.makePixelPositioned();

    this.updatePos();
    this.startPos = this.pos;

    this._dragging._startLeft = this._dragging.style.left;
    this._dragging._startTop = this._dragging.style.top;

    if (this.options.ghosting) {
      this._clone = this._dragging.cloneNode(true);
      this._dragging._originallyAbsolute = (this._dragging.getStyle('position') == 'absolute');
      if (!this._dragging._originallyAbsolute)
        Position.absolutize(this._dragging);
      this._dragging.parentNode.insertBefore(this._clone, this._dragging);
    } else {
      this._dragging.makePositioned();
    }
    this.updatePos();

    this._oldDragStyle = {};
    for (var s in this.options.dragStyle) {
      var os = this._dragging.getStyle(s);
      if (os !== null)
        this._oldDragStyle[s] = os;
    }
    this._dragging.setStyle(this.options.dragStyle);
    if (this.options.dragClass)
      this._dragging.addClassName(this.options.dragClass);

    Event.observe(document, 'mousemove', this.onMouseMove);

    Position.prepare();
    var ownScrollOffset = this._dragging.cumulativeScrollOffset();
    this.scrollOffset = this._dragging.offsetParent.cumulativeScrollOffset();
    var diff = [ownScrollOffset[0] - this.scrollOffset[0], ownScrollOffset[1] - this.scrollOffset[1]];
    this._dragging.setStyle({top: this.pos[1] - diff[1] + 'px', left: this.pos[0] - diff[0] + 'px'});
    this.scrollOffset[0] -= Position.deltaX;
    this.scrollOffset[1] -= Position.deltaY;

    var offset = this._dragging.cumulativeOffset();
    this.offset = [point[0] - offset[0], point[1] - offset[1]];

    this._lastMousePoint = point;

    if (this.options.startEffect)
      this.options.startEffect(this._dragging, this);
    if (this.options.onStart)
      this.options.onStart(this._dragging, this);

    this.startScrolling();
  },

  updatePos: function() {
    var tgt = this._dragging;
    this.pos = [parseInt(tgt.getStyle('left') || '0px'), parseInt(tgt.getStyle('top') || '0px')];
  },

  updateDrag: function(event) {
    // In case of delay this may happen
    if (this._timeout)
      return;

    var point = [Event.pointerX(event), Event.pointerY(event)];
    // Mozilla-based browsers fire successive mousemove events with
    // the same coordinates, prevent needless redrawing (moz bug?)
    if(this._lastMousePoint.inspect() == point.inspect()) return;
    this._lastMousePoint = point.clone();

    Droppable.update(this, event);

    this.updatePos();
    Position.prepare();
    var pagePos = this._dragging.cumulativeOffset();
    var scrollPos = this._dragging.offsetParent.cumulativeScrollOffset();
    var parentScrollOffset = this._dragging.offsetParent.cumulativeScrollOffset();
    scrollPos[0] -= this.scrollOffset[0];
    scrollPos[1] -= this.scrollOffset[1];
    scrollPos[0] -= Position.deltaX;
    scrollPos[1] -= Position.deltaY;

    /* Move the element by the amount the mousecursor is offset from the element's current position and subtract initial offset */
    var newpos = [this.pos[0] + point[0] - pagePos[0] + scrollPos[0] - this.offset[0], this.pos[1] + point[1] - pagePos[1] + scrollPos[1] - this.offset[1]];
    if (this.options.snap) {
      if(typeof this.options.snap == 'function') {
        newpos = this.options.snap(newpos[0],newpos[1],this);
      } else {
        if(this.options.snap instanceof Array) {
          newpos = newpos.map( function(v, i) {
            return Math.round(v/this.options.snap[i])*this.options.snap[i];
          }.bind(this));
        } else {
          newpos = newpos.map( function(v) {
            return Math.round(v/this.options.snap)*this.options.snap;
          }.bind(this));
        }
      }
    }
    if (this.options.constraint == 'horizontal')
      newpos[1] = this.pos[1];
    else if (this.options.constraint == 'vertical')
      newpos[0] = this.pos[0];
    this._dragging.setStyle({left: newpos[0] + 'px', top: newpos[1] + 'px'});
    if (this.options.onDrag)
      this.options.onDrag(this, this._dragging, point);
  },

  endDrag: function(event) {
    Event.stopObserving(document, 'mouseup', this.onMouseUp);
    if (this._timeout) {
      clearTimeout(this._timeout);
      this._timeout = null;
      this._dragging = null;
    } else {
      this.cleanupDrag(event);
    }
  },

  cleanupDrag: function(event) {
    this.stopScrolling();

    if (this.options.dragClass)
      tgt.removeClassName(this.options.dragClass);
    Event.stopObserving(document, 'mousemove', this.onMouseMove);
    this._dragging.setStyle(this._oldDragStyle);

    if (this.options.ghosting) {
      if (!this._dragging._originallyAbsolute)
        Position.relativize(this._dragging);
      Element.remove(this._clone);
      this._dragging._originallyAbsolute = false;
      this._clone = null;
    }

    this.updatePos();
    this._dropped = false;
    Droppable.notifyDrop(this, event);

    if (this.options.onEnd)
      this.options.onEnd(this._dragging, this);

    var revert = this.options.revert;
    if(revert && typeof revert == 'function')
      revert = revert(this._dragging, this);
    if (revert && (this.options.revertEffect) && (!this._dropped || (revert != 'failure')))
      this.options.revertEffect(this._dragging, this, this.pos[1] - this.startPos[1], this.pos[0] - this.startPos[0]);

    if (this.options.endEffect)
      this.options.endEffect(this._dragging, this);
    this._dragging = null;
    this._lastDroppable = null;
  },

  notifyDrop: function(droppable, point) {
    if (this.options.onDrop)
      this.options.onDrop(droppable, this, point);
    this._dropped = droppable;
  },

  notifyEnter: function(droppable, point) {
    this._lastDroppable = droppable;
    this._dragging._oldHoverStyle = {};
    for (var s in this.options.hoverStyle)
      this._oldHoverStyle[s] = tgt.getStyle(s);
    if (this.options.hoverClass)
      this._dragging.addClassName(this.options.hoverClass);
    this._dragging.setStyle(this.options.hoverStyle);
    if (this.options.onEnter)
      this.options.onEnter(droppable, this, pos);
  },

  notifyLeave: function(droppable, point) {
    if (this.options.hoverClass)
      this._dragging.removeClassName(this.options.hoverClass);
    this._dragging.setStyle(this._oldHoverStyle);
    if (this.options.onLeave)
      this.options.onLeave(droppable, this, pos);
  },
  startScrolling: function() {
    this.lastScrolled = new Date();
    this.scrollInterval = setInterval(function() { this.scroll();}.bind(this), 10);
  },

  stopScrolling: function() {
    if(this.scrollInterval) {
      clearInterval(this.scrollInterval);
      this.scrollInterval = null;
    }
  },
  scroll: function() {
    // this.lastDroppable = Droppable._lastActive, except it remembers when going outside the
    // Droppable while Droppable._lastActive will revert to false.
    if (!this._lastDroppable)
      return;
    var point = this._lastMousePoint;

    var current = new Date();
    var delta = current - this.lastScrolled;
    this.lastScrolled = current;

    Position.prepare();

    var element = this._lastDroppable._dropping || this._lastDroppable.element;

    while(element.offsetParent) {
      var offset = element.viewportOffset();
      // We don't want the element's own scroll offset
      offset[0] += element.scrollLeft + Position.deltaX;
      offset[1] += element.scrollTop + Position.deltaY;
      var dims = element.getDimensions();
      var dimensions = [];
      dimensions[0] = dims.width;
      dimensions[1] = dims.height;
      var amount = [0, 1].map(function(i) {
        // Before element's manifest position?  Then return speed * (cursor offset wrt left/top scroll boundary)
        if (point[i] < (offset[i] + this.options.scrollSensitivity[i])) {
          return -(((offset[i] + this.options.scrollSensitivity[i]) - point[i]) * this.options.scrollSpeed[i] * (delta / 1000));
        // After element's manifest position?  Then return speed * (cursor offset wrt right/bottom scroll boundary)
        } else if (point[i] > (offset[i] + dimensions[i] - this.options.scrollSensitivity[i])) {
          return ((point[i] - (offset[i] + dimensions[i] - this.options.scrollSensitivity[i])) * this.options.scrollSpeed[i] * (delta / 1000));
        } else
          return 0;
      }.bind(this));
      element.scrollLeft += amount[0];
      element.scrollTop += amount[1];
      element = element.parentNode;
    }
  }
};

/*--------------------------------------------------------------------------*/

var Sortable = Class.create();
Object.extend(Sortable, {
  SERIALIZE_RULE: /^[^_\-](?:[A-Za-z0-9\-\_]*)[_](.*)$/,
  inList: function() {
    var elements = $.apply(window, arguments); // $A(arguments).map($) does not work
    if (!(elements instanceof Array))
        elements = [elements];
    return function(draggable, droppable, point) {
      return elements.any(draggable._dragging.descendantOf.bind(draggable._dragging));
    };
  },
  isContainer: function(el) {
    return(el.tagName.toUpperCase() == 'UL');
  },
  isItem: function(el) {
    return(el.tagName.toUpperCase() == 'LI');
  }
});
Sortable.prototype = {
  initialize: function(element, options) {
    element = $(element);
    this.options = Object.extend({
      overlap: 'vertical',   // 'horizontal' or 'vertical', orientation of the sortable
      format: Sortable.SERIALIZE_RULE, // Format for serialization
      isContainer: Sortable.isContainer, // Function(element) that decides if element is a container element
      isItem: Sortable.isItem,           // Function(element) that decides if element is a sortable element
      tree: false,           // Should the sortable be a tree sortable (depth > 1)?
      only: false,           // Only use these classes (string-array or string) [strictly not needed.  Maybe this can be removed]
      onChange: false        // function(sortable, droppable, draggable) that gets triggered when the sortable's configuration is changed
    }, options || {});
    this.element = element;

    // For documentation on these options, see Draggable
    this.options.draggableOptions = Object.extend({
      findElement: this.findDragElement.bind(this),
      constraint: 'vertical',
      revert: true,
      onEnd: this.onEnd.bind(this),
      revertEffect: function(el) { el.setStyle({left: el._startLeft, top: el._startTop}); } // Set by initDrag
    }, this.options.draggableOptions || {});

    // For documentation on these options, see Droppable
    this.options.droppableOptions = Object.extend({
      findElement: Droppable.findElementDepth(false, !this.options.tree && 1), // If it's a tree, infinite levels deep, otherwise <= 1.
      onHover: this.onHover.bind(this),
      acceptOk: Sortable.inList(element)
    }, this.options.droppableOptions || {});

    this.draggable = new Draggable(this.element, this.options.draggableOptions);
    this.droppable = new Droppable(this.element, this.options.droppableOptions);
  },
  destroy: function() {
    this.droppable.destroy();
    this.draggable.destroy();
    if (this.options.tree)
      this.treenodes.each(function(n) { n.destroy(); });
  },
  /* Find the draggable element just below the sortable */
  findDragElement: function(element, draggable) {
    if (draggable.options.illegalTags.include(element.tagName.toUpperCase()) ||
       (draggable.options.handleClass && !element.hasClassName(draggable.options.handleClass)) ||
        !element.descendantOf(draggable.element))
      return false;
    if (!this.options.tree) {
      /* Travel down to the lowest level just below the sortable element */
      while (element.parentNode != draggable.element)
        element = element.parentNode;
    } else {
      while (!this.options.isContainer(element) && element.parentNode != draggable.element)
        element = element.parentNode;
    }
    return element;
  },
  onHover: function(draggable, droppable, point) {
    var element = draggable._dragging;

    var dropon = droppable._dropping;

    /* Position.prepare has been called by Droppable.update() */
    Position.within(dropon, point[0], point[1]);
    var overlap = Position.overlap(this.options.overlap, dropon);

    if (dropon == droppable.element) {
      if (dropon.immediateDescendants().length == 0 && this.options.isContainer(dropon))
        dropon.appendChild(element);
      return;
    }

    if (overlap > .33 && overlap < .66 && this.options.tree && this.options.isContainer(dropon)) {
      if (!element.descendantOf(dropon)) {
        // Fix for Gecko rendering problem
        if (!dropon._cleaned) {
          dropon.cleanWhitespace();
          dropon._cleaned = true;
        }
        element.setStyle({visibility: "hidden"}); // Avoid jittering
        dropon.appendChild(element);
      }
    } else if(this.options.isItem(dropon)) {
      // Fix for Gecko rendering problem
      if (!dropon.parentNode_cleaned) {
        dropon.parentNode.cleanWhitespace();
        dropon.parentNode._cleaned = true;
      }
      if (overlap < 0.5) {
        this.updateMarker(dropon, 'after');
        if (dropon.nextSibling != element) {
          element.setStyle({visibility: "hidden"}); // Avoid jittering
          dropon.parentNode.insertBefore(element, dropon.nextSibling || null);
        }
      } else { // overlap >= 0.5
        this.updateMarker(dropon, 'before');
        if (dropon.previousSibling != element) {
          element.setStyle({visibility: "hidden"}); // Avoid jittering
          dropon.parentNode.insertBefore(element, dropon);
        }
      }
    }
    element.setStyle({visibility: "visible"});
    // onLeave, but not quite
    if (draggable._lastSortable && draggable._lastSortable != this && draggable._lastSortable.options.onChange)
      draggable._lastSortable.options.onChange(draggable._lastSortable, draggable._lastSortable.droppable, draggable);

    draggable._lastSortable = this;
    if (this.options.onChange)
      this.options.onChange(this, droppable, draggable);
  },
  updateMarker: function(dropon, position) {
    // mark on ghosting only
    if(!this.draggable.options.ghosting) return;

    if(!this._marker) {
      this._marker =
        ($('dropmarker') || Element.extend(document.createElement('DIV'))).
          hide().addClassName('dropmarker').setStyle({position:'absolute'});
      document.getElementsByTagName("body").item(0).appendChild(this._marker);
    }
    var offsets = Position.cumulativeOffset(dropon);

    if(position=='after') {
      if(this.options.overlap == 'horizontal')
        offsets[0] += dropon.clientWidth;
      else
        offsets[1] += dropon.clientHeight;
    }
    this._marker.setStyle({left: offsets[0]+'px', top: offsets[1] + 'px'});
    this._marker.show();
  },
  onEnd: function() {
    if(this._marker)
      this._marker.hide();
  },
  findElements: function(element, options) {
    return Element.findChildren(
      element, options.only, options.tree ? true : false, options.isItem);
  },
  sequence: function(options) {
    options = Object.extend(this.options, options || {});

    return $(this.findElements(this.element, options) || []).map( function(item) {
      return item.id.match(options.format) ? item.id.match(options.format)[1] : '';
    });
  },
  setSequence: function(new_sequence, options) {
    options = Object.extend(this.options, options || {});

    var nodeMap = {};
    this.findElements(this.element, options).each( function(n) {
        if (n.id.match(options.format))
            nodeMap[n.id.match(options.format)[1]] = [n, n.parentNode];
        n.parentNode.removeChild(n);
    });
    new_sequence.each(function(ident) {
      var n = nodeMap[ident];
      if (n) {
        n[1].appendChild(n[0]);
        delete nodeMap[ident];
      }
    });
  },
  /* Construct a [i] index for a particular node */
  _constructIndex: function(node) {
    var index = '';
    do {
      if (node.id) index = '[' + node.position + ']' + index;
    } while ((node = node.parent) != null);
    return index;
  },
  serialize: function() {
    var options = Object.extend(this.options, arguments[0] || {});
    var name = encodeURIComponent(
      (arguments[0] && arguments[0].name) ? arguments[0].name : this.element.id);

    if (options.tree) {
      return this.tree(arguments[0]).children.map( function (item) {
        return [name + this._constructIndex(item) + "[id]=" +
                encodeURIComponent(item.id)].concat(item.children.map(arguments.callee.bind(this)));
      }.bind(this)).flatten().join('&');
    } else {
      return this.sequence(arguments[0]).map( function(item) {
        return name + "[]=" + encodeURIComponent(item);
      }).join('&');
    }
  },
  tree: function() {
    var sortableOptions = this.options;
    var options = Object.extend({
      isContainer: sortableOptions.isContainer,
      isItem: sortableOptions.isItem,
      only: sortableOptions.only,
      name: this.element.id,
      format: sortableOptions.format
    }, arguments[1] || {});

    var root = {
      id: null,
      parent: null,
      children: [],
      container: this.element,
      position: 0
    };

    return this._tree(this.element, options, root);
  },
  _tree: function(element, options, parent) {
    var children = this.findElements(element, options) || [];

    for (var i = 0; i < children.length; ++i) {
      var match = children[i].id.match(options.format);

      if (!match) continue;

      var child = {
        id: encodeURIComponent(match ? match[1] : null),
        element: element,
        parent: parent,
        children: [],
        position: parent.children.length,
        container: $(children[i]).descendants().find(options.isContainer)
      };

      /* Get the element containing the children and recurse over it */
      if (child.container)
        this._tree(child.container, options, child);

      parent.children.push (child);
    }

    return parent;
  }
};

Element.findChildren = function(element, only, recursive, isValid) {
  if(!element.hasChildNodes()) return null;
  if(only) only = [only].flatten();
  var elements = [];
  element.immediateDescendants().each(function(e) {
    if(isValid && isValid(e) &&
       (!only || (e.classNames().detect(function(v) { return only.include(v); }))))
      elements.push(e);
    if(recursive) {
      var grandchildren = Element.findChildren(e, only, recursive, isValid);
      if(grandchildren) elements.push(grandchildren);
    }
  });

  return (elements.length>0 ? elements.flatten() : []);
};