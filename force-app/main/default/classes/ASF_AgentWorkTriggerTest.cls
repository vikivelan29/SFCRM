@IsTest
public class ASF_AgentWorkTriggerTest {
	@Istest
    public static void testOne(){
        Case caseDet = new Case();
        insert caseDet;
        ServiceChannel sc = [SELECT Id
                FROM ServiceChannel WHERE DeveloperName = 'caseChannel'
                LIMIT 1];
        User systemUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isactive=true LIMIT 1];

		System.runAs(systemUser){
            try{
                AgentWork aw = new AgentWork();
                aw.UserId = UserInfo.getUserId();
                aw.WorkItemId = caseDet.Id;
                aw.ServiceChannelId = sc.Id;
                insert aw;
            }catch(Exception e){}
        }
    }

    @Istest
    public static void testTwo(){
        Case caseDet = new Case();
        insert caseDet;
        ServiceChannel sc = [SELECT Id
                FROM ServiceChannel WHERE DeveloperName = 'caseChannel'
                LIMIT 1];
        User systemUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isactive=true LIMIT 1];
        AgentWork aw = new AgentWork();
        aw.UserId = UserInfo.getUserId();
        aw.WorkItemId = caseDet.Id;
        aw.ServiceChannelId = sc.Id;
        Map<Id, AgentWork> newAgentWorkMapMock = new Map<Id, AgentWork>();
        newAgentWorkMapMock.put(caseDet.Id, aw);
        Test.startTest();
        ASF_AgentWorkTriggerHandler inst = new ASF_AgentWorkTriggerHandler();
        inst.afterInsert(newAgentWorkMapMock);
        Test.stopTest();
    }
}