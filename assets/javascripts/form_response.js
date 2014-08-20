var FormItem = Class.create();
FormItem.prototype = {
  initialize: function(element, options) {
    this.options = options;
    this.id = element.replace(/.*_([^_]+)$/, '$1');
    this.element = $(element);
    this.element.getItem = function() { return this; }.bind(this);
    this.addEventListeners();
  },

  addEventListeners: function() {
    var f = this.changed.bindAsEventListener(this);
    Element.getElementsBySelector(this.element, 'input,select,textarea').each(function(el) {
      Event.observe(el, 'change', f);
    });
    // Add a hack/workaround to make IE report changes in radio and checkboxes immediately
    // upon click or keypress instead of after blurring.
    // Thanks to http://norman.walsh.name/2009/03/24/jQueryIE#comment0012
    if (Prototype.Browser.IE) {
      Element.getElementsBySelector(this.element, 'input:radio, input:checkbox').each(function (el) {
        Event.observe(el, 'click', function() { el.blur(); el.focus(); });
        Event.observe(el, 'keyUp', function() { el.blur(); el.focus(); });
      });
    }
  },

  changed: function(event) {
    var form = this.getFormVars();
    new Ajax.Request(FormBuilderConfig.root_path + '/form_item/validate', 
                     {parameters: Object.extend(form, {form_id: $F('form_id')})});
    form = {"item_ids[]": []};
    this.getDependees().each(function(d) {
      var item = d.getItem();
      form['item_ids[]'].push(item.id);
      form = Object.extend(form, item.getDependentFormVars());
    });
    new Ajax.Request(FormBuilderConfig.root_path + '/form_item/update_visibility/',
                     {parameters: Object.extend(form, {form_id: $F('form_id')})});
  },
  
  getFormVars: function() {
    return Form.serializeElements(this.element.descendants(), true);
  },
  
  getDependencies: function() {
    return (this.options.dependencies || []).map(function(id) { return $('form-item_'+id); });
  },

  getDependees: function() {
    return (this.options.dependees || []).map(function(id) { return $('form-item_'+id); });
  },
  
  getDependentFormVars: function() {
    var deps = this.getDependencies();
    var form = {};
    if (deps.all(Element.visible)) {
      deps.each(function(el) {
        var item = el.getItem();
        Object.extend(form, item.getFormVars());
      });
    }
    return form;
  },

  destroy: function() {
    this.element.remove();
  }
};
