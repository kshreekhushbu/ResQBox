module.exports = {
  apps: [
    {
      name: 'resQbox_dev',
      script: 'server/server.js',
      env: {
        NODE_ENV: 'development'
      }
    },
    {
      name: 'resQbox_prod',
      script: 'server/server.js',
      env: {
        NODE_ENV: 'production'
      }
    }
  ]
};
