var FormBuilderConfig = {
  root_path: ''
};

/*
 * Extract information from an element's classes or its id based on a regex.
 * The classname that matches the regex is taken, the regex part is
 * discarded and what remains is returned.
 */
Element.addMethods({
  extract_class_info: function(element, regex) {
    var info = element.classNames().grep(regex, function(x) { return x.sub(regex, ''); });
    return info ? info[0] : null;
  },
  extract_id_info: function(element, regex) {
    var info = element.id;
    return (info && info.match(regex)) ? info.sub(regex, '') : null;
  }
});