require 'fileutils'
count = 1
Dir['/Users/user/git/twilight/app/models/**.rb'].each do |file|
  if File.ftype(file) == 'file'
    buffer = IO.readlines(file)
    skip = IO.readlines(file).grep(/include Auditable/).empty?
    if skip
      filtered = buffer.select { |l| (l =~ /^\s*#/).nil? }
      #puts buffer[0]
      if filtered[0] =~ /\s*class\s+.*ActiveRecord::Base/
        puts "#{file[36..-1]}"
        n=1
        buffer.each do |line|
          if line =~ /\s*class\s+.*ActiveRecord::Base/
            break
          else
            n += 1
          end
        end
        out = buffer.insert(n, "  include Auditable\n").join
        FileUtils.mv file, file+'.orig'
        File.open(file, 'w') { |f| f.write out }
        exit if count > 1000
        count += 1
      end
    end
  end
end


