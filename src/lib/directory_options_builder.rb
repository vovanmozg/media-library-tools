class DirectoryOptionsBuilder
  def call(base_path, prefix = "")
    options = []
    parent_options = []

    base_path2 = base_path

    parts = base_path2.split('/')
    # /vt/new/data -> ['/vt', '/vt/new', '/vt/new/data']

    while parts.size > 1
      parent_options << { name: "#{prefix}#{parts.join('/')}", path: parts.join('/'), ancestor: true }
      parts.pop
    end

    options += parent_options.reverse

    Dir.entries(base_path).sort.each do |entry|
      next if entry == '.' || entry == '..'
      full_path = File.join(base_path, entry)
      if File.directory?(full_path)
        options << { name: "#{prefix}#{entry}", path: full_path }
      end
    end
    options
  end
end
