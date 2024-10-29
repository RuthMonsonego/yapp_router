typedef enum bit {COV_ENABLE, COV_DISABLE} cover_e;

class yapp_tx_monitor extends uvm_monitor;

  // Collected Data handle
  yapp_packet pkt;

  // Count packets collected
  int num_pkt_col;

  virtual interface yapp_if vif;

  cover_e coverage_control = COV_ENABLE;

  uvm_analysis_port #(yapp_packet) item_collected_port;

  // component macro
  `uvm_component_utils_begin(yapp_tx_monitor)
    `uvm_field_int(num_pkt_col, UVM_ALL_ON)
    `uvm_field_enum(cover_e, coverage_control, UVM_ALL_ON)
  `uvm_component_utils_end

  covergroup coverage;
    req1 : coverpoint pkt.length{
      bins maximum = {63};
      bins minimum = {1};
      bins smalll = {[2:10]};
      bins mediumm = {[11:40]};
      bins largee = {[41:62]};
    }
    req2 : coverpoint pkt.addr{
      bins addr[] = {[0:2]};
      bins illegal = {3};
    }
    req3 : coverpoint pkt.parity_type{
      bins bad = {BAD_PARITY};
      bins good = default;
    }
    c1 : cross req1, req2;
    c2 : cross req2, req3;
  endgroup

  // component constructor - required syntax for UVM automation and utilities
  function new (string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
    if (coverage_control == COV_ENABLE) begin
     `uvm_info(get_type_name(),"YAPP MONITOR COVERAGE CREATED" , UVM_LOW)
      coverage = new();
      coverage.set_inst_name({get_full_name(), ".monitor_pkt"});
    end
  endfunction : new

  function void connect_phase(uvm_phase phase);
    if (!yapp_vif_config::get(this, get_full_name(),"vif", vif))
      `uvm_error("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})
  endfunction: connect_phase

  task run_phase(uvm_phase phase);
    // Look for packets after reset
    @(posedge vif.reset)
    @(negedge vif.reset)
    `uvm_info(get_type_name(), "Detected Reset Done", UVM_MEDIUM)
    forever begin 
      // Create collected packet instance
      pkt = yapp_packet::type_id::create("pkt", this);

      fork
        // collect packet
        vif.collect_packet(pkt.length, pkt.addr, pkt.payload, pkt.parity);
        // trigger transaction at start of packet
        @(posedge vif.monstart) void'(begin_tr(pkt, "Monitor_YAPP_Packet"));
      join

      pkt.parity_type = (pkt.parity == pkt.calc_parity()) ? GOOD_PARITY : BAD_PARITY;
      // End transaction recording
      end_tr(pkt);
      `uvm_info(get_type_name(), $sformatf("Packet Collected :\n%s", pkt.sprint()), UVM_NONE)
      item_collected_port.write(pkt);
      // trigger coverage
      if (coverage_control == COV_ENABLE) begin
        `uvm_info(get_type_name(),"YAPP MONITOR COVERAGE SAMPLE" , UVM_NONE)
        coverage.sample();
      end
      num_pkt_col++;
    end
  endtask : run_phase

  // UVM report_phase
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("Report: YAPP Monitor Collected %0d Packets", num_pkt_col), UVM_LOW)
  endfunction : report_phase

endclass : yapp_tx_monitor