trigger Launch_Async_Class_Trigger on Launch_Async_Class__e (after insert) {
    for(Launch_Async_Class__e event : trigger.new){
        if(String.isNotBlank(event.Class_Name__c)){
            Type classType = Type.forName(event.Class_Name__c);
            Object classInstance = classType.newInstance();
            if(classInstance instanceof Database.Batchable<sObject>) {
                    Database.executeBatch((Database.Batchable<sObject>) classInstance,event.Batch_Size__c==null?200:event.Batch_Size__c.intValue());
            } else if (classInstance instanceof System.Queueable) {
                System.enqueueJob((System.Queueable) classInstance);
            }
        }
    }
}