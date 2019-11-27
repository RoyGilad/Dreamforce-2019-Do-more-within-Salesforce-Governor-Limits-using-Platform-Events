trigger Groupmembership_Event_Trigger on groupMembership__e (after insert) {
    List<groupMember> newMembers = new List<groupMember>();
    List<groupMember> membersToDelete = new List<groupMember>();
    
    Map<String, Map<id, groupMember>> GroupNameToUserIDToMemberIDMap = new Map<String, Map<id, groupMember>>();
        
    // Let's build a set of all Group Names mentioned in the published events so we can query them to get the group ID
    Set<String> groupNames = new Set<String>();
    For(groupMembership__e me : trigger.new){
        groupNames.add(me.GroupName__c);
    }
    
    Map<String, ID> groupIDByNameMap = new Map<String, ID>();
    Map<ID, String> groupNameByIDMap = new Map<ID, String>();
    for (group g : [select id, Name from group where Name in : groupNames]){
        groupIDByNameMap.put(g.Name, g.id);
        groupNameByIDMap.put(g.id, g.Name);
    }

    // Let's get all existing members for any of the groups in this trigger.
    // We then put them into a Map or Maps, where the key to the first map is the group name, and the internal map has user id's mapped to the groupMembership record
    For (groupMember m : [SELECT id, userOrGroupId, groupId from groupMember where groupId in : groupNameByIDMap.keySet()]){
        //The map already has a key with this group member's group name
        If(GroupNameToUserIDToMemberIDMap.containsKey(groupIDByNameMap.get(m.groupId))){
            GroupNameToUserIDToMemberIDMap.get(groupNameByIDMap.get(m.groupId)).put(m.userOrGroupID, m);
        } Else {
            GroupNameToUserIDToMemberIDMap.put(groupNameByIDMap.get(m.groupId), new Map<id, groupMember>{m.userOrGroupID => m});
        }
    }
    System.debug('Group Members Map:'+GroupNameToUserIDToMemberIDMap);
    
    // Now iterate through the published membership events so we can figure out what needs to happen:
    // - If GroupAdd - check if the user is already a member:
    //   - If User already a member, do nothing
    //   - If User not a member, create a groupMember record
    // - If GroupRemove - find the existing GroupMember record, and if one exists, delete it.

    For(groupMembership__e me : trigger.new){
        System.debug('Iterating over Platform Event: '+me);
        // If we need to add a member to the group:
        // Check the the map doesn't already contain this user as a member of the group (cannot add if they are already in it...)
        if ('GroupAdd'.equalsIgnoreCase(me.type__c) && (!GroupNameToUserIDToMemberIDMap.containsKey(me.groupName__c)||(GroupNameToUserIDToMemberIDMap.containsKey(me.groupName__c) && !GroupNameToUserIDToMemberIDMap.get(me.groupName__c).containsKey(me.userID__c)))){
            System.debug('In Group Add with event: '+me);
            groupMember gm = new groupMember();
            gm.groupId = groupIDByNameMap.get(me.groupName__c);
            gm.UserOrGroupID = me.userId__c;
            newMembers.add(gm);
        }
        // If we need to remove the member AND the member actually exists
        if ('GroupRemove'.equalsIgnoreCase(me.type__c) && GroupNameToUserIDToMemberIDMap.containsKey(me.groupName__c) && GroupNameToUserIDToMemberIDMap.get(me.groupName__c).containsKey(me.userID__c)){
            System.debug('In Group Remove with event: '+me);
            membersToDelete.add(GroupNameToUserIDToMemberIDMap.get(me.groupName__c).get(me.userID__c));
        }
    }
    If(newMembers.size()>0){
        insert newMembers;
    }

    If(membersToDelete.size()>0){
        delete membersToDelete;
    }
}