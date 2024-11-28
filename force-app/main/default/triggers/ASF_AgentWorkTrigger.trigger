trigger ASF_AgentWorkTrigger on AgentWork (before insert, after insert) {
	TriggerDispatcher.Run(new ASF_AgentWorkTriggerHandler());
}