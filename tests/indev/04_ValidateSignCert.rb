# Validate Cert Signing
# Accepts hash of parsed config file as arg
class ValidateSignCert
  attr_accessor :config, :fail_flag 
  def initialize(config)
    self.config    = config
    self.fail_flag = 0

    host=""
    os=""
    test_name="Validate Sign Cert"
    usr_home=ENV['HOME']
    pmaster=""
    agent_list=""

    # Parse config for Master and Agents
    @config["HOSTS"].each_key do|host|
      if /^AGENT/ =~ os then           # Build flat list Agent Nodes
        agent_list = host + " " + agent_list
      end
      if /^PMASTER/ =~ os then         # Detect Puppet Master node
        pmaster = host
      end
    end

    # AGENT(s) intiate Cert Signing with PMASTER
    @config["HOSTS"].each_key do|host|
      if /^AGENT/ =~ os then        # Detect Puppet Agent node
        BeginTest.new(host, test_name)
        runner = RemoteExec.new(host)
        #result = runner.do_remote("puppetd --server #{pmaster} --waitforcert 30")
        result = runner.do_remote("puppetd --server puppet.puppetlabs.lan --waitforcert 60 --test")
        @fail_flag+=result.exit_code
        ChkResult.new(host, test_name, result.stdout, result.stderr, result.exit_code)
      end
    end
    sleep 3

    # Sign Agent Certs from PMASTER
    test_name="Puppet Master Sign Requested Agent Certs"
    BeginTest.new(pmaster, test_name)
    runner = RemoteExec.new(pmaster)
    result = runner.do_remote("puppetca --sign pagent.puppetlabs.lan")
    @fail_flag+=result.exit_code
    ChkResult.new(host, test_name, result.stdout, result.stderr, result.exit_code)

  end
end
