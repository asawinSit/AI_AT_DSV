// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "BasePawn.h"
#include "Tank.generated.h"

/**
 * 
 */
UCLASS()
class TOONTANKS_API ATank : public ABasePawn
{
	GENERATED_BODY()

public:
	// Sets default values for this pawn's properties
	ATank();
	void HandleDestruction();

	APlayerController* GetTankPlayerController() const {return TankPlayerController;}
protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	
	
public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	bool bAlive = true;

private:
	UPROPERTY(EditAnywhere, meta=(AllowPrivateAccess = "true"), Category = "Components")
	class USpringArmComponent* SpringArm;
	
	UPROPERTY(EditAnywhere, meta=(AllowPrivateAccess = "true"), Category = "Components")
	class UCameraComponent* Camera;

	
	
	void Move(float Value);
	void Turn(float Value);
	
	UPROPERTY(EditAnywhere, Category = "Movement")
	float Speed {5.0f};

	UPROPERTY(EditAnywhere, Category = "Movement")
	float TurnRate {5.0f};

	APlayerController* TankPlayerController;
};
