module UniqueNumbers
  class AlphaNumericGenerator < Generator

    store_accessor :settings, :minimum, :maximum, :max_tries, :scope

    after_initialize do |generator|
      generator.minimum ||= 0
      generator.maximum ||= 10**8 - 1
      generator.max_tries ||= 100
    end

    def assign_next_number(model = nil, attribute = nil, debug = false)
      self.with_lock do
        max_tries.times do
          value = (1..9).to_a[rand(9)].to_s + SecureRandom.alphanumeric(5).upcase
          now = Time.now
          model_scope = model.class.base_class
          case scope
          when :daily
            model_scope = model_scope.where('DATE(created_at) = ?', Date.today)
          end
          if !model_scope.exists?(attribute => formatted_number(value, now))
            self.last_generated_at = now
            self.save!
            model.update_columns(attribute => formatted_number(value, now))
            return
          end
        end
        model.errors.add(attribute, "maximum number of generation tries reached")
        raise ActiveRecord::RecordInvalid, model
      end
    end
  end
end
