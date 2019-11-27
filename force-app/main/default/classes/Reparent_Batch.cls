public class Reparent_Batch implements Database.Batchable<sObject>{
    public ID fromUserId;
    public ID previousRoleId;

    public Reparent_Batch(id fromUserId, id previousRoleId){
        this.fromUserId = fromUserId;
        this.previousRoleId = previousRoleId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        string queryString = 'SELECT id, ownerId from Opportunity WHERE ownerID =: fromUserId';
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        //Do all the work 
        For(Opportunity opp : scope){
            System.debug('Updating stuff');
        }
        // DO a bunch of other stuff here....
        //update scope;
	}
	
	public void finish(Database.BatchableContext BC) {
		// Let's try to enqueue both queueables
        //System.enqueueJob(new ExportChangesToERP_Qable());
        //System.enqueueJob(new Recalc_Commission_Qable());
        
        // Using Platform Events
        List<launch_async_class__e> eventsToPublish = new List<launch_async_class__e>();
        eventsToPublish.add(new launch_async_class__e(class_name__c = 'ExportChangesToERP_Qable'));
        eventsToPublish.add(new launch_async_class__e(class_name__c = 'Recalc_Commission_Qable'));
        
        If(eventsToPublish.size()>0){
            eventBus.publish(eventsToPublish);
        }

	}
}