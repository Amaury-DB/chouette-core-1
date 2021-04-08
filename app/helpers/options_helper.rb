module OptionsHelper

  def option_input form, export, attr, option_def, type
    attr = option_def[:name] if option_def[:name].present?
    parent_form ||= form

    opts = {
      input_html: {value: export.try(attr) || option_def[:default_value]},
      as: option_def[:type],
      selected: export.try(attr) || option_def[:default_value]
    }

    if option_def[:hidden]
      opts[:as] = :hidden
    elsif option_def[:ajax_collection]
      opts[:as] = :select
      opts[:input_html].merge!({'data-domain-name': request.base_url})
      opts[:collection] = []
    elsif option_def[:type].to_s == "boolean"
      opts[:as] = :switchable_checkbox
      opts[:input_html][:checked] = export.try(attr) || option_def[:default_value]
    elsif option_def[:type].to_s == "array"
      opts[:as] = :tags
      opts[:input_html].merge!({'data-select2ed-placeholder': t('simple_form.custom_inputs.tags.placeholder')})
      opts[:wrapper_html]  = { class: '.tags'}
    end
    if option_def.has_key?(:collection)
      if option_def[:collection].is_a?(Array) && !option_def[:collection].first.is_a?(Array)
        opts[:collection] = option_def[:collection].map{|k| [translate_option_value(type, attr, k), k]}
      else
        opts[:collection] = option_def[:collection]
      end
      opts[:collection] = export.instance_exec(&option_def[:collection]) if option_def[:collection].is_a?(Proc)

      opts[:collection] = opts[:collection].push([t('none'), nil]) if option_def[:allow_blank]
    end
    opts[:label] =  translate_option_key(type, attr)
    out = form.input attr, opts

    if option_def[:depends]
      klass = 'slave'
      klass << ' hidden' if option_def[:hidden]
      out = content_tag :div, class: klass, data: { master: "[name='#{parent_form.object_name}[#{option_def[:depends][:option]}]']", value: option_def[:depends][:value] } do
        out
      end.html_safe
    end
    out
  end

  def display_option_value record, option_name
    option = record.option_def(option_name)
    val = record.options[option_name.to_s]

    if option[:display]
      self.instance_exec(val, &option[:display])
    elsif option[:type] == :boolean
      val.to_s.t
    elsif option.has_key?(:collection)
      translate_option_value(record.object.class, option_name, val)
    else
      val
    end
  end

  def translate_option_key(parent_class, key)
    root = parent_class
    root = Destination if root < Destination
    root.tmf("#{parent_class.name.demodulize.underscore}.#{key}")
  end

  def translate_option_value(parent_class, attr, key)
    root = parent_class
    root = Destination if root < Destination
    root.tmf("#{parent_class.name.demodulize.underscore}.#{attr}_collection.#{key}", default: key)
  end

end
