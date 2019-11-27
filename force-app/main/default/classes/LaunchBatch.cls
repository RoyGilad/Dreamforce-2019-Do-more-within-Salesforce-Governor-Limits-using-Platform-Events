public class LaunchBatch {
    public static void run() {
        User u = [select id, UserRoleId from User where email = 'ohad+df19@getpraxis.com'];
        id fromUser = u.id;
        id roleID =  u.UserRoleId;
        Reparent_Batch rb = new Reparent_Batch(fromUser, roleId);
        database.executeBatch(rb);
    }
}