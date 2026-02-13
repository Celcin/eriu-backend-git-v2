<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('doctrine', [
		'orm' => [
			'auto_generate_proxy_classes' => false,
			'proxy_dir' => '%kernel.build_dir%/doctrine/orm/Proxies',
			'query_cache_driver' => [
				'type' => 'pool',
				'pool' => 'doctrine.system_cache_pool',
			],
			'result_cache_driver' => [
				'type' => 'pool',
				'pool' => 'doctrine.result_cache_pool',
			],
		],
	]);

	$container->extension('framework', [
		'cache' => [
			'pools' => [
				'doctrine.result_cache_pool' => [
					'adapters' => ['cache.app'],
				],
				'doctrine.system_cache_pool' => [
					'adapters' => ['cache.system'],
				],
			],
		],
	]);
};
