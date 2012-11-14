require 'pathname'
require 'tempfile'
require 'chef/mixin/checksum'
require 'chef/provider/file'

module ChefMustache

    module MustacheTemplate 
        include Chef::Mixin::Checksum

        def render_template(source, context)
            begin
                open(source, 'r') do |file|
                    yield Mustache.render(file.read(), context)
                end
            rescue Object => e
                raise MustacheError.new(e, template, context)
            end
        end
    end

    class MustacheError < RuntimeError
        attr_reader :original_exception, :context
        SOURCE_CONTEXT_WINDOW = 2

        def initialize(original_exception, template, context)
            @original_exception, @template, @context = original_exception, template, context
        end

        def message
            @original_exception.message
        end

        def to_s
            "\n\n#{self.class} (#{message})\n\n"
        end
    end

end

