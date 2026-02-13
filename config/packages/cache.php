<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('framework', [
		'cache' => [
			'app' => 'cache.adapter.redis',
			'default_redis_provider' => '%env(REDIS_URL)%',
		],
	]);
};
