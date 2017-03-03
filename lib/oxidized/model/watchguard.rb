class Watchguard < Oxidized::Model

  prompt /^\[?\w*\]?\w*<?\w*>?#\s*$/
  comment  '-- '

  cmd :all do |cfg|
    cfg.each_line.to_a[1..-2].join
  end

  cmd 'show sysinfo' do |cfg|
    # avoid commits due to uptime
    cfg = cfg.each_line.select { |line| not line.match /(.*time.*)|(.*memory.*)|(.*cpu.*)/ }
    cfg = cfg.join
    comment cfg
  end

  cmd 'export config to console'

  cfg :ssh do
    pre_logout 'exit'
  end

end