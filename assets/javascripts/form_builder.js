/* Calculate the offset in percentages where the left edge of an item begins relative to its parent. */
function calcOffset(parent, child) {
  var width = parent.clientWidth;
  var left_padding = parseInt(parent.getStyle('padding-left')) || 0;
  width -= left_padding;
  width -= parseInt(parent.getStyle('padding-right')) || 0;
  return (child.offsetLeft - left_padding - parent.offsetLeft - parent.clientLeft) / width * 100;
};

var Toolbox = Class.create();
Toolbox.prototype = {
  initialize: function(element, toolClass) {
    this.element = $(element);
    this.toolClass = toolClass;
    this.addEventListeners();
  },

  addEventListeners: function() {
    this.draggable = new Draggable(this.element, {findElement: Draggable.findElementClass(this.toolClass), revert: true});
  }
};

var Ruler = Class.create();
Ruler.prototype = {
  initialize: function(element, repos_img, marker_img, canvas) {
    this.element = $(element);
    this.repos_img = repos_img;
    this.marker_img = marker_img;
    this.createRepos();
    this.addEventListeners();
    this.markers = [];
    this.canvas = canvas;
    canvas.ruler = this;
  },

  addEventListeners: function() {
    this.draggable_markers = new Draggable(this.element, {findElement: Draggable.findElementClass('marker'), constraint: 'horizontal', ghosting: true, onEnd: this.moveMarker.bind(this), onDrag: this.dragMarker.bind(this)});
    this.draggable_repos = new Draggable(this.repos, {constraint: 'horizontal', revert: true, onEnd: this.dropRepos.bind(this) });
  },

  /*
   * The repos is the place where new markers come from.  You drag it and when
   * you drop it a new marker is created at that spot.
   */
  createRepos: function() {
    var img = $(document.createElement('img'));
    img.src = this.repos_img;
    img.alt = '_|';
    img.setStyle({top: 0, left: '100%', position: 'relative', 'float': 'left', marginLeft: '-100%'});
    this.element.appendChild(img);
    this.repos = img;
  },

  /* Add a new marker at the given position (in percentages starting at the left edge of the canvas) */
  addMarker: function(pos) {
    var img = $(document.createElement('img'));
    img.src = this.marker_img;
    img.alt = "V";
    img.addClassName('marker');
    this.element.appendChild(img);
    img.setStyle({top: 0, left: '100%', position: 'relative', 'float': 'left', marginLeft: -1 * (100 - pos) + '%'});
    this.markers.push(img);
  },

  /* Create a new marker where the marker repos was dropped */
  dropRepos: function(droppable, draggable, pos) {
    var offset = calcOffset(this.element, draggable._dragging);
    if (offset < 0 || offset > 100)
      return; // Don't add the marker
    this.addMarker(offset);
    this.updateMarkers();
  },

  /*
   * Let the server know the marker was moved to a new position.
   * If it is moved to the far left or right of the canvas, it is
   * removed from the list.
   */
  moveMarker: function(droppable, draggable, pos) {
    var offset = calcOffset(this.element, draggable._dragging);
    if (offset < 0 || offset > 100) {
      this.markers = this.markers.without(draggable._dragging);
      draggable._dragging.remove();
    } else {
      draggable._dragging.setStyle({marginLeft: '-' + (100 - offset) + '%', left: '100%'});
    }
    this.updateMarkers();
  },

  dragMarker: function(droppable, draggable, pos) {
    /*
     * There should be a very thin DIV that runs straight through all lines, so you can see the alignment of the items with this marker.
     * That should be dragged along with the img.
     */
  },

  /* Send marker positions to the servers, in percentage offsets */
  updateMarkers: function() {
    var markerPositions = this.markers.inject([], function(all, marker) {
      all.push(calcOffset(this.element, marker));
      return all;
    }.bind(this));
    new Ajax.Request(FormBuilderConfig.root_path + '/form/update_ruler',
                     {parameters: {id: this.canvas.form_id,
                                   'positions[]': markerPositions}});
  }
};

var FormCanvas = Class.create();
FormCanvas.prototype = {
  initialize: function(element, toolClass, form_id, ruler) {
    this.element = $(element);
    this.toolClass = toolClass;
    this.addEventListeners();
    this.form_id = form_id;
    this.ruler = ruler;
    this.deltaSnap = 25;  // In pixels
  },

  addEventListeners: function() {
    // Position: relative messes up positioning when moving around items
    this.sortable_lines = new Sortable(this.element, {tree: true,
                                                      isContainer: function(el) { return(el.hasClassName('canvas') || el.hasClassName('element-for-form_group')); },
                                                      isItem: function(el) { return(el.hasClassName('line')); },
                                                      draggableOptions: {findElement: function(el) { return el.hasClassName('line') && el; }, onDrop: this.reArranged.bind(this), onEnd: function(el) { el.setStyle({position: null}); } },
                                                      droppableOptions: {accept: 'line' } });
//    this.sortable_lines.serialize = this.serializeLineOrder.bind(this);
    this.droppable_tools = new Droppable(this.element, {accept: this.toolClass, onDrop: this.dropTool.bind(this) });
    this.droppable_tools_lines = new Droppable(this.element, {accept: this.toolClass, findElement: Droppable.findElementClass('line', 'element-for-form_group'), onDrop: this.dropTool.bind(this) });
    this.droppable_items = new Droppable(this.element, {accept: 'form-item', findElement: Droppable.findElementClass('line'), onDrop: this.acceptDroppable.bind(this) });
    this.draggable_items = new Draggable(this.element, {findElement: Draggable.findElementClass('form-item'), onDrop: this.moveItem.bind(this), snap: this.snapToRulers.bind(this), ghosting: true, delay: 200, onEnd: function(el) { el.setStyle({top: null}); }});
  },

  // We need something slightly more descriptive than the positions of item nodes in container nodes.
  serializeLineOrder: function() {
    // HACK:  Just return the old style, without support for FormGroups.  Remove comment above when we want to implement.
  },

  acceptDroppable: function(draggable, droppable) {
    droppable._dropping.appendChild(draggable._dragging);
  },

  /*
   * Snap the dragged item to the rulers set by the user if the snap to rulers
   * function is enabled and the user gets within this.deltaSnap pixels of the ruler.
   */
  snapToRulers: function(x, y) {
    if (!$('snap-to-rulers').checked || this.ruler.markers.length == 0)
      return [x, y];
    /* We look at marker[0] twice.  Do we care? */
    var closest = this.ruler.markers.inject(this.ruler.markers[0].cumulativeOffset()[0], function(closest, marker) {
      var xpos = marker.cumulativeOffset()[0];
      if (Math.abs(x - xpos) < Math.abs(x - closest))
        return xpos;
      else
        return closest;
    });

    if (Math.abs(x - closest) < this.deltaSnap)
      return [closest, y];
    else
      return [x, y];
  },

  /* Move an item from one line to another */
  moveItem: function(droppable, draggable, pos) {
    var percentageOffset = calcOffset(droppable._dropping, draggable._dragging);
    draggable._dragging.setStyle({marginLeft: '-' + (100 - percentageOffset + '%'), left: '100%'});
    new Ajax.Request(FormBuilderConfig.root_path + '/form_item/move_to_line',
                     {parameters: {id: draggable._dragging.extract_id_info(/^form-item_/),
                                   'item[form_line_id]': droppable._dropping.extract_id_info(/^line_/),
                                   'item[offset]': percentageOffset}});
  },

  /* Rearrange form lines */
  reArranged: function(droppable, draggable, pos) {
    new Ajax.Request(FormBuilderConfig.root_path + '/form/rearrange',
                     {parameters: this.sortable_lines.serialize() + '&id=' + this.form_id});
  },

  /* Drop a tool on a particular line, creating a new Item instance */
  dropTool: function(draggable, droppable, pos) {
    var params = {
      item_class: draggable._dragging.extract_class_info(/^tool-for-/),
      id: this.form_id,
      'item[offset]': calcOffset(droppable._dropping, draggable._dragging)
    };
    var line_id = droppable._dropping.extract_id_info(/^line_/);
    if (line_id)
      params.line_id = line_id;
    var formgroup_id = droppable._dropping.extract_id_info(/^form-item_/);
    if (formgroup_id && droppable._dropping.hasClassName('element-for-form_group'))
      params.formgroup_id = formgroup_id;
    new Ajax.Request(FormBuilderConfig.root_path + '/form/new_item', {parameters: params});
  }
};


var FormItem = Class.create();
FormItem.prototype = {
  initialize: function(element) {
    this.element = $(element);
    this.element.getItem = function() { return this; }.bind(this);
    this.addEventListeners();
  },

  reload: function() {
    new Ajax.Request(FormBuilderConfig.root_path + '/form_item/update_properties', {parameters: {id: this.element.extract_id_info(/^form-item_/)}});
  },

  addEventListeners: function() {
    Event.observe(this.element, 'click', this.showProperties.bindAsEventListener(this));
  },

  showProperties: function(event) {
    if (!this.element.hasClassName('selected'))
      new Ajax.Request(FormBuilderConfig.root_path + '/form_item/properties', {parameters: {id: this.element.extract_id_info(/^form-item_/)}});
    Event.stop(event);
  },

  destroy: function() {
    this.element.remove();
  }
};
