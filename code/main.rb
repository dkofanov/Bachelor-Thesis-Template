#!/usr/bin/env ruby

require 'erb'

class CrossValues
  def initialize
    @target_gen_dir = ARGV[0]
    @constants_gen_dir = @target_gen_dir + "/generated_values"
    @asm_defines = File.read(ARGV[1]).scan(/DEFINE_VALUE\((\w+),/).sort_by(&:first)
    @consts_tmpl = ERB.new(File.read(ARGV[2]), trim_mode: "-")
    @getters_tmpl = ERB.new(File.read(ARGV[3]), trim_mode: "-")
    
    @archs = []
    (4..ARGV.size - 1).step(2).each do |i|
      pair = []
      pair.append(ARGV[i])
      pair.append(File.read(ARGV[i + 1]).scan(/"\^\^(\w+) [#\$]?([-+]?\d+)\^\^"/).sort_by(&:first))
      @archs.append(pair)
    end
    @arch_cursor = 0
    Dir.mkdir(@target_gen_dir) unless File.exists?(@target_gen_dir)
    Dir.mkdir(@constants_gen_dir) unless File.exists?(@constants_gen_dir)
  end

  def update_arch_cursor
    @arch_cursor = (@arch_cursor + 1) % @archs.size
  end

  def asm_defines
    @asm_defines
  end

  def libasm_defines
    @archs[@arch_cursor][1]
  end

  def arch
    @archs[@arch_cursor][0]
  end

  def archs
    @archs
  end

  def generate_constants
    @archs.each do |arch|
      File.open(@constants_gen_dir + "/#{arch[0]}_values_gen.h", "w") do |file|
        file.write(@consts_tmpl.result)
      end
      update_arch_cursor
    end
  end

  def generate_getters
    File.open(@target_gen_dir + "/cross_values.h", "w") do |file|
      file.write(@getters_tmpl.result)
    end
  end
end

# ARGV[0] - target_gen_dir
# ARGV[1] - asm_defines.def
# ARGV[2] - consts_template.erb
# ARGV[3] - getters_template.erb
# ARGV[n + 0] - arch name
# ARGV[n + 1] - arch's libasm_defines.S
CV = CrossValues.new;
CV.generate_constants
CV.generate_getters
