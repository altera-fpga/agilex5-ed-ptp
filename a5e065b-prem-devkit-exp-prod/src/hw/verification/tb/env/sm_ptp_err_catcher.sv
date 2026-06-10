`ifndef GUARD_SM_PTP_ERR_CATCHER_SV
 `define GUARD_SM_PTP_ERR_CATCHER_SV

/** Base class for all report catchers */
class sm_ptp_err_catcher extends svt_err_catcher;

  /**
   * Queue that contains message severity to match along with message text to be
   * demoted.  Multiple message severity can be demoted by pushing multiple values
   * to the queue. Each entry in this queue needs to have matching entry in 
   * messages_to_demote queue.
   */
  protected uvm_severity severity_to_demote[$];

  function new(string name="sm_ptp_err_catcher");
    super.new(name);

    add_message_text_to_demote("/Body definition undefined/");
    add_message_severity_to_demote(UVM_WARNING);
  endfunction

  function action_e catch();
    foreach(messages_to_demote[i]) begin
`ifdef SVT_UVM_TECHNOLOGY
      if(!uvm_re_match(messages_to_demote[i], get_message())) begin
`elsif SVT_OVM_TECHNOLOGY
      if(ovm_is_match(messages_to_demote[i], get_message())) begin
`endif
        if(get_severity() == severity_to_demote[i]) begin
          void'(super.catch());
        end
      end
    end
    return THROW;
  endfunction

  // ---------------------------------------------------------------------------
  /**
   * Adds a new regex entry that will be used to match against the message severity
   * 
   * @param severity Regex expression used to match the message text
   */
  function void add_message_severity_to_demote(uvm_severity severity);
    severity_to_demote.push_back(severity);
  endfunction

endclass // sm_ptp_err_catcher

`endif //  `ifndef GUARD_SM_PTP_ERR_CATCHER_SV
