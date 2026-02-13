<?php

declare(strict_types=1);

namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function (ContainerConfigurator $container): void
{
	$container->extension('flysystem', [
		'storages' => [
			'default.storage' => [
				'adapter' => 'local',
				'options' => [
					'directory' => '%kernel.project_dir%/var/storage',
				],
			],
		],
	]);
};
