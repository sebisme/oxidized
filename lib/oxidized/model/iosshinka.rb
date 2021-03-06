class IOS < Oxidized::Model

  prompt /^([\w.@()-]+[#>]\s?)$/
  comment  '! '

  # example how to handle pager
  #expect /^\s--More--\s+.*$/ do |data, re|
  #  send ' '
  #  data.sub re, ''
  #end

  # non-preferred way to handle additional PW prompt
  #expect /^[\w.]+>$/ do |data|
  #  send "enable\n"
  #  send vars(:enable) + "\n"
  #  data
  #end

  cmd :all do |cfg|
    #cfg.gsub! /\cH+\s{8}/, ''         # example how to handle pager
    #cfg.gsub! /\cH+/, ''              # example how to handle pager
    cfg.each_line.to_a[1..-2].join
  end

  cmd :secret do |cfg|
    cfg.gsub! /^(snmp-server community).*/, '\\1 <configuration removed>'
    cfg.gsub! /username (\S+) privilege (\d+) (\S+).*/, '<secret hidden>'
    cfg.gsub! /^username \S+ password \d \S+/, '<secret hidden>'
    cfg.gsub! /^enable password \d \S+/, '<secret hidden>'
    cfg.gsub! /wpa-psk ascii \d \S+/, '<secret hidden>'
    cfg.gsub! /^tacacs-server key \d \S+/, '<secret hidden>'
    cfg
  end

  cmd 'show version' do |cfg|
    comment cfg.lines.first
  end

  cmd 'show inventory' do |cfg|
    comment cfg
  end

  cmd 'show vtp status' do |cfg|
    comment cfg
  end

  cmd 'show vtp password' do |cfg|
    comment cfg
  end

  cmd 'show vlan' do |cfg|
    expect /^\s--More--\s+.*$/ do |data, re|
      send ' '
      data.sub re, ''
    end
    comment cfg
  end

  cmd 'show running-config' do |cfg|
    cfg = cfg.each_line.to_a[3..-1]
    cfg = cfg.reject { |line| line.match /^ntp clock-period / }.join
    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
    cfg.gsub! /^\ tunnel\ mpls\ traffic-eng\ bandwidth[^\n]*\n*(
                  (?:\ [^\n]*\n*)*
                  tunnel\ mpls\ traffic-eng\ auto-bw)/mx, '\1'
    cfg
  end

  # cmd 'more vlan.dat' do |cfg|
  #   expect /^\s--More--\s+.*$/ do |data, re|
  #     send ' '
  #     data.sub re, ''
  #   end
  #   cfg
  # end

  # cmd 'more vlan.dat' do |cfg|
  #   expect /^\s--More--\s+.*$/ do |data, re|
  #     send ' '
  #     data.sub re, ''
  #   end
  #   cfg
  # end

  cfg :telnet do
    username /^Username:/
    password /^Password:/
  end
  
  cfg :telnet, :ssh do
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    # preferred way to handle additional passwords
    if vars :enable
      post_login do
        send "enable\n"
        cmd vars(:enable)
      end
    end
    if vars :push_files
      pre_logout do
        Oxidized.logger.info "TFTP : "+vars(:tftp_address)
        filename = @node.name
        filename = filename.gsub(/[^0-9A-Za-z.\-]/, '')
        filename.downcase!
        filename += '_copyvlan_'
        filename += Time.now.strftime('%Y%m%d%H%M%S')
        filename
        send "copy running-config tftp\n"
        send vars(:push_address)+"\n"
        send filename+"\n"
      end
    end
    #pre_logout 'exit'
    pre_logout 'exit'
  end
end