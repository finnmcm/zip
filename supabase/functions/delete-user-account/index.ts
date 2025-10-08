import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";

serve(async (req) => {
  try {
    // Create Supabase client with service role key for admin operations
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Get the user from the request context (automatically provided by Supabase)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No authorization header provided" }),
        { 
          headers: { "Content-Type": "application/json" },
          status: 401 
        }
      );
    }

    // Extract JWT token
    const jwt = authHeader.replace("Bearer ", "");
    
    // Verify the user and get their information
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(jwt);
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "User not found or invalid token" }),
        { 
          headers: { "Content-Type": "application/json" },
          status: 401 
        }
      );
    }

    const userId = user.id;
    console.log(`🗑️ Starting account deletion for user: ${user.email} (${userId})`);

    // Delete user data from database tables in correct order
    try {
      // 1. Delete order items first (references orders)
      console.log("🗑️ Deleting order items...");
      const orderIdsResponse = await supabaseClient
        .from("orders")
        .select("id")
        .eq("user_id", userId);
      
      if (orderIdsResponse.data && orderIdsResponse.data.length > 0) {
        const orderIds = orderIdsResponse.data.map(order => order.id);
        const { error: orderItemsError } = await supabaseClient
          .from("order_items")
          .delete()
          .in("order_id", orderIds);
        
        if (orderItemsError) {
          console.error("❌ Error deleting order items:", orderItemsError);
          throw orderItemsError;
        }
      }

      // 2. Delete orders
      console.log("🗑️ Deleting orders...");
      const { error: ordersError } = await supabaseClient
        .from("orders")
        .delete()
        .eq("user_id", userId);
      
      if (ordersError) {
        console.error("❌ Error deleting orders:", ordersError);
        throw ordersError;
      }

      // 3. Delete FCM tokens
      console.log("🗑️ Deleting FCM tokens...");
      const { error: fcmError } = await supabaseClient
        .from("fcm_tokens")
        .delete()
        .eq("user_id", userId);
      
      if (fcmError) {
        console.error("❌ Error deleting FCM tokens:", fcmError);
        throw fcmError;
      }

      // 4. Delete user record
      console.log("🗑️ Deleting user record...");
      const { error: userRecordError } = await supabaseClient
        .from("users")
        .delete()
        .eq("id", userId);
      
      if (userRecordError) {
        console.error("❌ Error deleting user record:", userRecordError);
        throw userRecordError;
      }

      // 5. Finally, delete the user from Auth
      console.log("🗑️ Deleting user from Auth...");
      const { error: authDeleteError } = await supabaseClient.auth.admin.deleteUser(userId);
      
      if (authDeleteError) {
        console.error("❌ Error deleting user from Auth:", authDeleteError);
        throw authDeleteError;
      }

      console.log(`✅ Successfully deleted account for user: ${user.email}`);
      
      return new Response(
        JSON.stringify({ 
          success: true,
          message: "Account deleted successfully",
          userId: userId
        }),
        { 
          headers: { "Content-Type": "application/json" },
          status: 200 
        }
      );

    } catch (dbError) {
      console.error("❌ Database deletion error:", dbError);
      return new Response(
        JSON.stringify({ 
          error: "Failed to delete user data from database",
          details: dbError.message 
        }),
        { 
          headers: { "Content-Type": "application/json" },
          status: 500 
        }
      );
    }

  } catch (error) {
    console.error("❌ Account deletion error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Account deletion failed",
        details: error.message 
      }),
      { 
        headers: { "Content-Type": "application/json" },
        status: 500 
      }
    );
  }
});
