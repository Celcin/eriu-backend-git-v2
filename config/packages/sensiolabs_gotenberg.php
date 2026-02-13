<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('sensiolabs_gotenberg', [
		'http_client' => 'gotenberg.client',
	]);

	$container->extension('framework', [
		'http_client' => [
			'scoped_clients' => [
				'gotenberg.client' => [
					'base_uri' => '%env(GOTENBERG_URL)%',
				],
			],
		],
	]);
};
