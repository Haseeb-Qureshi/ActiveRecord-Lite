module Validatable
  def validates(m, validations)
    var = instance_variable_get(m)
    validations.each do |validation, option|
      case validation
      when :presence then raise ValidationError, "not present" unless var
      when :length
        min, max = option[:minimum], option[:maximum]
        raise ValidationError, "shorter than min" if min && var < min
        raise ValidationError, "longer than max" if max && var > max
      when :numericality
        raise ValidationError, "not a number" if !var.is_a?(Fixnum)
      end
    end
  end

  def validate(m, *validations)
    validations.each do |validation|
      raise ValidationError if !send(validation, m)
    end
  end
end

class ValidationError < StandardError
end
