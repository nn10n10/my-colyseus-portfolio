/**
 * Infrastructure Configuration for Phase 3
 * This file contains all connection information for AWS resources
 */

export const InfrastructureConfig = {
  // AWS Region
  region: process.env.AWS_REGION || 'ap-northeast-1',

  // Redis Configuration
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    // Add connection options as needed
    options: {
      retryDelayOnFailover: 100,
      maxRetriesPerRequest: 3,
      lazyConnect: true,
    }
  },

  // DynamoDB Configuration
  dynamodb: {
    region: process.env.AWS_REGION || 'ap-northeast-1',
    tables: {
      users: process.env.USERS_TABLE || 'colyseus-users',
      gameSessions: process.env.GAME_SESSIONS_TABLE || 'colyseus-game-sessions',
      gameHistory: process.env.GAME_HISTORY_TABLE || 'colyseus-game-history'
    }
  },

  // Application Configuration
  app: {
    port: parseInt(process.env.PORT || '2567'),
    nodeEnv: process.env.NODE_ENV || 'development',
  },

  // Load Balancer Configuration (for health checks and monitoring)
  loadBalancer: {
    healthCheckPath: process.env.HEALTH_CHECK_PATH || '/',
    healthCheckInterval: parseInt(process.env.HEALTH_CHECK_INTERVAL || '30'),
  }
};

// Environment variable validation
export function validateConfig(): boolean {
  const required = [
    'REDIS_HOST',
    'USERS_TABLE',
    'GAME_SESSIONS_TABLE',
    'GAME_HISTORY_TABLE'
  ];

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    console.warn(`Missing environment variables: ${missing.join(', ')}`);
    console.warn('Using default values - check configuration for production environment');
    return false;
  }

  return true;
}

// Helper function to get Redis connection string
export function getRedisConnectionString(): string {
  return `redis://${InfrastructureConfig.redis.host}:${InfrastructureConfig.redis.port}`;
}

export default InfrastructureConfig;