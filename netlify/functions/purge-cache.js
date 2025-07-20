import { purgeCache } from "@netlify/functions"

export default async (request, context) => {
  try {
    // Purge all cached content
    await purgeCache({
      tags: ["all"] // This will clear everything
    });
    
    return new Response("🧹 Cache purged successfully! Your site should now show the latest version.", {
      status: 200,
      headers: {
        "Content-Type": "text/plain"
      }
    });
  } catch (error) {
    return new Response(`Cache purge failed: ${error.message}`, {
      status: 500,
      headers: {
        "Content-Type": "text/plain"
      }
    });
  }
}

export const config = {
  path: "/api/purge-cache"
}