import config from "@colyseus/tools";
import { monitor } from "@colyseus/monitor";
import { playground } from "@colyseus/playground";
import { InfrastructureConfig, validateConfig } from "./infrastructure.config";

/**
 * Import your Room files
 */
import { MyRoom } from "./rooms/MyRoom";

export default config({

    initializeGameServer: (gameServer) => {
        /**
         * Validate infrastructure configuration
         */
        if (!validateConfig()) {
            console.warn("⚠️  Some infrastructure environment variables are missing. Check logs for details.");
        }

        /**
         * Define your room handlers:
         */
        gameServer.define('my_room', MyRoom);

        console.log("🎮 Colyseus Game Server initialized");
        console.log(`🌐 Environment: ${InfrastructureConfig.app.nodeEnv}`);
        console.log(`📊 Port: ${InfrastructureConfig.app.port}`);
        console.log(`🗄️  Redis: ${InfrastructureConfig.redis.host}:${InfrastructureConfig.redis.port}`);
        console.log(`💾 DynamoDB Tables: ${Object.values(InfrastructureConfig.dynamodb.tables).join(', ')}`);
    },

    initializeExpress: (app) => {
        /**
         * Health check endpoint for ALB
         */
        app.get("/", (_req, res) => {
            res.status(200).json({
                status: "healthy",
                timestamp: new Date().toISOString(),
                service: "colyseus-game-server",
                version: "1.0.0"
            });
        });

        /**
         * Infrastructure status endpoint
         */
        app.get("/health", async (_req, res) => {
            try {
                // Basic health check - can be extended to test Redis/DynamoDB connectivity
                const healthStatus = {
                    status: "healthy",
                    timestamp: new Date().toISOString(),
                    services: {
                        colyseus: "healthy",
                        redis: "configured",
                        dynamodb: "configured"
                    },
                    environment: InfrastructureConfig.app.nodeEnv
                };
                res.status(200).json(healthStatus);
            } catch (error) {
                res.status(503).json({
                    status: "unhealthy",
                    timestamp: new Date().toISOString(),
                    error: error instanceof Error ? error.message : "Unknown error"
                });
            }
        });

        /**
         * Legacy endpoint for backward compatibility
         */
        app.get("/hello_world", (_req, res) => {
            res.send("It's time to kick ass and chew bubblegum!");
        });

        /**
         * Use @colyseus/playground
         * (It is not recommended to expose this route in a production environment)
         */
        if (InfrastructureConfig.app.nodeEnv !== "production") {
            app.use("/", playground());
        }

        /**
         * Use @colyseus/monitor
         * It is recommended to protect this route with a password
         * Read more: https://docs.colyseus.io/tools/monitor/#restrict-access-to-the-panel-using-a-password
         */
        app.use("/monitor", monitor());
    },


    beforeListen: () => {
        /**
         * Before before gameServer.listen() is called.
         */
        console.log("🚀 Server starting up...");
        console.log(`📍 AWS Region: ${InfrastructureConfig.region}`);
        console.log(`🎯 Phase 3 infrastructure is ready!`);
    }
});
